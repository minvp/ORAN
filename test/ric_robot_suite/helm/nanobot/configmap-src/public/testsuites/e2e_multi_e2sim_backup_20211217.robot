############################################################################################
# Vietnam Team - Nanobot Practices - Multiple E2SIM E2E Testing                            #
############################################################################################
*** Settings ***
Resource          /robot/resources/e2mgr_interface.robot
Resource          /robot/resources/global_properties.robot
Resource          /robot/resources/json_templater.robot
Resource          /robot/resources/appmgr_interface.robot
Library           Collections
Library           String
Library           RequestsLibrary
Library           UUID
Library           StringTemplater
Library           OperatingSystem
Library           KubernetesEntity  ${GLOBAL_RICPLT_NAMESPACE}

*** Variables ***
${E2MGR_BASE_PATH}     v1/nodeb
${SUBMGR_BASE_PATH}     ric/v1

*** Keywords ***
Count gNB in Connected Status on E2Mgr
     [Documentation]   Count gNB in Connected Status on E2Mgr
     ${data_path} =    Set Variable             ${E2MGR_BASE_PATH}/states
     ${resp} =         Run E2Mgr GET Request    ${data_path}
     ${list_gnb} =        Set Variable    ${resp.json()}
     ${list_count} =         Create List
     FOR    ${item}    IN    @{list_gnb}
         ${status} =   Get From Dictionary    ${item}    connectionStatus
         Append To List    ${list_count}     ${status}
     END
     Log To Console    ${list_count}
     ${count} =     Count Values In List    ${list_count}    CONNECTED
     [Return]          ${count}

RetriveLog From E2SIM
	 [Documentation]     RetriveLog From E2SIM
     ${e2simpodname} =   Run Keyword     RetrievePodsForDeployment       ${Global_RAN_DEPLOYMENT}   namespace=${Global_RAN_NAMESPACE}
     Log To Console      ${e2simpodname}
     ${e2sim_pod1} =     Set Variable       ${e2simpodname[0]}
     Log To Console      ${e2sim_pod1}
     ${e2sim_log} =       Run keyword     RetrieveLogForPod       ${e2sim_pod1}   namespace=${Global_RAN_NAMESPACE}
     ${e2sim_12001} =     Get Match Count    ${e2sim_log}    *10110101110001100111011110001*      #RIC_E2_SETUP_REQ
     ${e2sim_12002} =     Get Match Count    ${e2sim_log}    *10101010110011001110*               #RIC_E2_SETUP_RESP
     ${e2sim_12050} =     Get Match Count    ${e2sim_log}    *Sent RIC Indication*                #RIC_INDICATION
     ${e2sim_12040} =     Get Match Count    ${e2sim_log}    *Received RIC Control*               #RIC_CONTROL_REQ
     ${e2sim_12041} =     Get Match Count    ${e2sim_log}     *Bouncer Control OK*                #RIC_CONTROL_ACK
     ${e2sim_12050_12040} =      Create List
     FOR    ${item}     IN      ${e2sim_log}
            ${list_time_diff} =   Get Matches    ${item}    *Time diff in Microseconds*
     END
     Log To Console       ${list_time_diff}
     FOR    ${item}     IN      @{list_time_diff}
            ${time_1}  ${time_2} =   Split String   ${item}  :${SPACE}
            ${time_num} =    Convert To Integer    ${time_2}
            Append To List   ${e2sim_12050_12040}   ${time_num}
     END
     ${e2sim_12050_12040_max} =     Evaluate    max(${e2sim_12050_12040})
     ${e2sim_12050_12040_min} =     Evaluate    min(${e2sim_12050_12040})
     Log To Console              Max Time Differrent between RIC_INDICATION(12050) and RIC_CONTROL_REQ(12040): ${e2sim_12050_12040_max}
     Log To Console              Min Time Differrent between RIC_INDICATION(12050) and RIC_CONTROL_REQ(12040): ${e2sim_12050_12040_min}
     Log To Console              Number of RIC_E2_SETUP_REQ(12001) messages sent by E2SIM: ${e2sim_12001}
     Log To Console              Number of RIC_E2_SETUP_RESP(12002) messages received on E2SIM: ${e2sim_12002}
     Log To Console              Number of RIC_INDICATION(12050) messages sent by E2SIM: ${e2sim_12050}
     Log To Console              Number of RIC_CONTROL_REQ(12040) messages received on E2SIM: ${e2sim_12040}
     Log To Console              Number of RIC_CONTROL_ACK(12041) messages received on E2SIM: ${e2sim_12041}
     Set Global Variable         ${e2sim_12001}
     Set Global Variable         ${e2sim_12002}
     Set Global Variable         ${e2sim_12050}
     Set Global Variable         ${e2sim_12040}
     Set Global Variable         ${e2sim_12041}
     Set Global Variable         ${e2sim_12050_12040_max}
     Set Global Variable         ${e2sim_12050_12040_min}

RetriveLog From E2Mgr
	[Documentation]      RetriveLog From E2Mgr
    ${podname} =         Run Keyword     RetrievePodsForDeployment       deployment-ricplt-e2mgr      namespace=ricplt
    Log To Console       ${podname}
    ${ric_E2Mgr_pod1} =  Set Variable    ${podname[0]}
    Log To Console       ${ric_E2Mgr_pod1}
    ${E2MGR_log} =       Run keyword     RetrieveLogForPod       ${ric_E2Mgr_pod1}       namespace=ricplt
    ${e2mgr_12001} =     Get Match Count    ${E2MGR_log}    *MType: 12001*     #RIC_E2_SETUP_REQ
    ${e2mgr_12002} =     Get Match Count    ${E2MGR_log}    *MType: 12002*     #RIC_E2_SETUP_RESP
    Log To Console       Number of RIC_E2_SETUP_REQ(12001) messages received on E2Mgr: ${e2mgr_12001}
    Log To Console       Number of RIC_E2_SETUP_RESP(12002) messages sent by E2Mgr: ${e2mgr_12002}
    Set Global Variable    ${e2mgr_12001}
    Set Global Variable    ${e2mgr_12002}

RetriveLog From SubMgr
    [Documentation]      RetriveLog From SubMgr
    ${submgrpodname} =   Run Keyword     RetrievePodsForDeployment    deployment-ricplt-submgr    namespace=ricplt
    Log To Console       ${submgrpodname}
    ${submgr_pod1} =     Set Variable     ${submgrpodname[0]}
    Log To Console       ${submgr_pod1}
    ${submr_log} =       Run keyword    RetrieveLogForPod    ${submgr_pod1}     namespace=ricplt
    ${submgr_12010} =    Get Match Count    ${submr_log}    *MSG from XAPP*    #RIC_SUB_REQ
    ${submgr_12011} =    Get Match Count    ${submr_log}    *MSG to XAPP*      #RIC_SUB_RESP
    Log To Console       Number of RIC_SUB_REQ(12010) received on SubMgr: ${submgr_12010}
    Log To Console       Number of RIC_SUB_RESP(12011) sent by SugMgr: ${submgr_12011}
    Set Global Variable  ${submgr_12010}
    Set Global Variable  ${submgr_12011}

RetriveLog From BouncerxApp
    [Documentation]     RetriveLog From BouncerxApp
    ${podname} =        Run Keyword     RetrievePodsForDeployment       ${GLOBAL_XAPP_DEPLOYMENT}      namespace=ricxapp
    LOG TO CONSOLE      ${podname}
    ${ric_xapp_pod1} =  Set Variable    ${podname[0]}
    LOG TO CONSOLE      ${ric_xapp_pod1}
    ${xapp_log} =       Run keyword     RetrieveLogForPod       ${ric_xapp_pod1}       namespace=ricxapp
    ${xapp_12010} =     Get Match Count   ${xapp_log}    *Transmitted subscription request*                     #RIC_SUB_REQ
    ${xapp_12011} =     Get Match Count   ${xapp_log}    *Received subscription message of type = 12011*        #RIC_SUB_RESP
    ${xapp_12050} =     Get Match Count   ${xapp_log}    *Received indication message of type = 12050*          #RIC_INDICATION
    ${xapp_12040} =     Get Match Count   ${xapp_log}    *RMR Return to Sender Message of Type: 12040*          #RIC_CONTROL_REQ
    ${xapp_12041} =     Get Match Count   ${xapp_log}    *RMR Return to Sender Message: Bouncer Control OK*     #RIC_CONTROL_ACK
    Log To Console      Number of RIC_SUB_REQ(12010) messages sent by xApp: ${xapp_12010}
    Log To Console      Number of RIC_SUB_RESP(12011) messages received on xApp: ${xapp_12011}
    Log To Console      Number of RIC_INDICATION(12050) messages received on xApp: ${xapp_12050}
    Log To Console      Number of RIC_CONTROL_REQ(12040) messages sent by xApp: ${xapp_12040}
    Log To Console      Number of RIC_CONTROL_ACK(12041) messages sent by xApp: ${xapp_12041}
    Set Global Variable    ${xapp_12010}
    Set Global Variable    ${xapp_12011}
    Set Global Variable    ${xapp_12050}
    Set Global Variable    ${xapp_12040}
    Set Global Variable    ${xapp_12041}

#Count gNB Subscription Success on SubMgr
#     [Documentation]   Count gNB Subscription Success on SubMgr

*** Test Cases ***
############################################################################################
# Multiple E2SIM - Testing Prepareation                                                    #
############################################################################################

#TC.01 - Ensure E2SIM is deployed and available
#    [Tags]  multi_e2sim_e2e
#    ${ctrl} =   Run Keyword     deployment      ${Global_RAN_DEPLOYMENT}        ${Global_RAN_NAMESPACE}
#    Should Be Equal      ${ctrl.status.replicas}          ${ctrl.status.ready_replicas}
#
#TC.02 - RIC xApp Onboarder is deployed and available
#    [Tags]  multi_e2sim_e2e
#    ${controllerName} =     Set Variable    ${GLOBAL_TEST_XAPP_ONBOARDER}
#    ${cType}  ${name} =     Split String    ${controllerName}   \|
#    ${ctrl} =  Run Keyword      ${cType}        ${name}
#    Should Be Equal      ${ctrl.status.replicas}          ${ctrl.status.ready_replicas}
#
#TC.03 - Deploy Bouncer xApp
#    [Tags]  multi_e2sim_e2e
#    Deploy XApp       ${TEST_XAPPNAME}

TC.04 - Wait For Internal Processes
    #Bouncer xApp will start to send RIC_SUB_REQ messages after deployed 100s
    #Bouncer xApp will send RIC_SUB_REQ messages to SubMgr one by one every 16s
    ${timer} =    Evaluate   ${GLOBAL_TOTAL_NODEB} * 16  + 100
    Log To Console    Please wait for internal processes (in seconds)... ${timer}
    Sleep     ${timer}



############################################################################################
# Multiple E2SIM - E2 Setup procedure verification between E2SIM and RICPLT                #
############################################################################################

TC.05 - RetriveLog From E2SIM
     [Tags]   multi_e2sim_e2e
     RetriveLog From E2SIM

TC.06 - RetriveLog From E2Mgr
     [Tags]   multi_e2sim_e2e
     RetriveLog From E2Mgr

TC.07 - Count E2 Setup Success
     [Tags]   multi_e2sim_e2e
     ${count_gnb_connected} =    Count gNB in Connected Status on E2Mgr
     Log To Console   Total deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
     Log To Console   Total gNodeB in CONNECTED status: ${count_gnb_connected}
     Set Global Variable    ${count_gnb_connected}
     Should Be Equal As Strings    ${count_gnb_connected}    ${GLOBAL_TOTAL_NODEB}

TC.08 - Count E2 Setup Request messages sent by E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console     Number of deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
     Log To Console     Number of E2 Setup Request messages sent by E2SIM: ${e2sim_12001}
     Should Be Equal As Strings    ${e2sim_12001}    ${GLOBAL_TOTAL_NODEB}

TC.09 - Count E2 Setup Request messages received on E2Mgr
     [Tags]   multi_e2sim_e2e
     Log To Console     Number of E2 Setup Request messages sent by E2SIM: ${e2sim_12001}
     Log To Console     Number of E2 Setup Request messages received on E2Mgr: ${e2mgr_12001}
     Should Be Equal As Strings    ${e2mgr_12001}    ${e2sim_12001}

TC.10 - Count E2 Setup Response messages sent by E2Mgr
     [Tags]   multi_e2sim_e2e
     Log To Console     Number of E2 Setup Request messages received on E2Mgr: ${e2mgr_12001}
     Log To Console     Number of E2 Setup Response messages sent by E2Mgr: ${e2mgr_12002}
     Should Be Equal As Strings    ${e2mgr_12001}    ${e2mgr_12002}

TC.11 - Count E2 Setup Response messages received on E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console     Number of E2 Setup Response messages sent by E2Mgr: ${e2mgr_12002}
     Log To Console     Number of E2 Setup Response messages received on E2SIM: ${e2sim_12002}
     Should Be Equal As Strings    ${e2sim_12002}    ${e2mgr_12002}


############################################################################################
# Multiple E2SIM - Subscription procedure verification between Bouncer xApp and E2SIM      #
############################################################################################
TC.12 - RetriveLog From SubMgr
    [Tags]   multi_e2sim_e2e
    RetriveLog From SubMgr

TC.13 - RetriveLog From BouncerxApp
    [Tags]  multi_e2sim_e2e
    RetriveLog From BouncerxApp

#TC.14 - Count Subscription Success
#     [Tags]   multi_e2sim_e2e
#	 ${count_sub_success} =    Count gNB Subscription Success on SubMgr
#	 Should Be Equal As Strings    ${count_sub_success}    ${GLOBAL_TOTAL_NODEB}

TC.15 - Count RIC Subscription Request messages sent by xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of Connected gNB: ${count_gnb_connected}
     Log To Console    Number of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Should Be Equal As Strings    ${count_gnb_connected}    ${xapp_12010}

TC.16 - Count RIC Subscription Request messages received on SubMgr
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Log To Console    Number of RIC Subscription Request Received on SubMgr: ${submgr_12010}
     Should Be Equal As Strings    ${submgr_12010}    ${xapp_12010}

TC.17 - Count RIC Subscription Response messages sent by SubMgr
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Subscription Request Received from xApp: ${submgr_12010}
     Log To Console    Number of RIC Subscription Response Received on xApp: ${submgr_12011}
     Should Be Equal As Strings    ${submgr_12010}    ${submgr_12011}

TC.18- Count RIC Subscription Response messages received on xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Subscription Response Sent by SubMgr: ${submgr_12011}
     Log To Console    Number of RIC Subscription Response Received on xApp: ${xapp_12011}
     Log To Console    Number of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Should Be Equal As Strings    ${submgr_12011}    ${xapp_12011}
     Should Be Equal As Strings    ${xapp_12010}    ${xapp_12011}

TC.19 - Count RIC Indication messages sent by E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of gNB Subscription Success on SubMgr: ${count_sub_success}
     Log To Console    Number of RIC Indication Sent by E2SIM: ${e2sim_12050}
     Should Be Equal As Strings    ${count_sub_success}    ${e2sim_12050}

TC.20 - Count RIC Indication messages received on xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Indication Sent by E2SIM: ${e2sim_12050}
     Log To Console    Number of RIC Indication Received on xApp: ${xapp_12050}
     Should Be Equal As Strings    ${xapp_12050}    ${e2sim_12050}

TC.21 - Count RIC Control messages sent by xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Control messages Sent by xApp: ${xapp_12040}
     Log To Console    Number of RIC Indication messages Received on xApp: ${xapp_12050}
     Should Be Equal As Strings    ${xapp_12040}    ${xapp_12050}

TC.22 - Count RIC Control messages received on E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console    Number of RIC Control messages Sent by xApp: ${xapp_12040}
     Log To Console    Number of RIC Control messages Received on E2SIM: ${e2sim_12040}
     Should Be Equal As Strings    ${xapp_12040}    ${e2sim_12040}

TC.23 - Max Diff Time between Indication and Control messages
     [Tags]   multi_e2sim_e2e
     Log To Console    Max Diff Time between Indication and Control messages: {e2sim_12050_12040_max}

TC.24 - Min Diff Time between Indication and Control messages
     [Tags]   multi_e2sim_e2e
     Log To Console    Min Diff Time between Indication and Control messages: {e2sim_12050_12040_min}

#TC.25 - Undeploy The Deployed XApp
#    Undeploy XApp     ${TEST_XAPPNAME}

