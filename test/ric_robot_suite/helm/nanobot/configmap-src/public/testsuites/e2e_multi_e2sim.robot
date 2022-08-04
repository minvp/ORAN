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
Library           SSHLibrary

Suite Setup     SSH to OS with ROOT

*** Variables ***
${E2MGR_BASE_PATH}      v1/nodeb
${SUBMGR_BASE_PATH}     ric/v1
${SUBMGR_ENDPOINT}      ${GLOBAL_SUBMGR_SERVER_PROTOCOL}://${GLOBAL_INJECTED_SUBMGR_IP_ADDR}:${GLOBAL_SUBMGR_HTTP_PORT}
${TEST_XAPPNAME}        ${GLOBAL_TEST_XAPP}
${GLOBAL_CLUSTER_IP}    192.168.56.200
*** Keywords ***
SSH to OS with ROOT
    Open Connection     ${GLOBAL_CLUSTER_IP}
    ${output}=      Login       phuong      phuong
    Should Contain      ${output}       Last login
    Start Command       pwd
    ${pwd}=     Read Command Output
    Should Be Equal     ${pwd}      /home/phuong
    ${input}=     Write       sudo -i
    ${output}=      Read        delay=0.5s
    Should Contain      ${output}       [sudo] password for phuong:
    ${input}=     Write       phuong
    ${output}=      Read        delay=0.5s
    Should Contain      ${output}       root@


RetriveLog From E2SIM
	 [Documentation]     RetriveLog From E2SIM
     ${e2simpodname} =   Run Keyword     RetrievePodsForDeployment       ${Global_RAN_DEPLOYMENT}   namespace=${Global_RAN_NAMESPACE}
     ${e2sim_pod1} =     Set Variable       ${e2simpodname[0]}
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
     FOR    ${item}     IN      @{list_time_diff}
            ${time_1}  ${time_2} =   Split String   ${item}  :${SPACE}
            ${time_num} =    Convert To Integer    ${time_2}
            Append To List   ${e2sim_12050_12040}   ${time_num}
     END
     ${e2sim_12050_12040_max} =     Evaluate    max(${e2sim_12050_12040})
     ${e2sim_12050_12040_min} =     Evaluate    min(${e2sim_12050_12040})
     Log To Console              \nNumber of RIC_E2_SETUP_REQ(12001) messages sent by E2SIM: ${e2sim_12001}
     Log To Console              Number of RIC_E2_SETUP_RESP(12002) messages received on E2SIM: ${e2sim_12002}
     Log To Console              Number of RIC_INDICATION(12050) messages sent by E2SIM: ${e2sim_12050}
     Log To Console              Number of RIC_CONTROL_REQ(12040) messages received on E2SIM: ${e2sim_12040}
     Log To Console              Number of RIC_CONTROL_ACK(12041) messages sent by E2SIM: ${e2sim_12041}
     Log To Console              Max Time Differrent between RIC_INDICATION(12050) and RIC_CONTROL_REQ(12040): ${e2sim_12050_12040_max}
     Log To Console              Min Time Differrent between RIC_INDICATION(12050) and RIC_CONTROL_REQ(12040): ${e2sim_12050_12040_min}
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
    ${ric_E2Mgr_pod1} =  Set Variable    ${podname[0]}
    ${E2MGR_log} =       Run keyword     RetrieveLogForPod       ${ric_E2Mgr_pod1}       namespace=ricplt
    ${e2mgr_12001} =     Get Match Count    ${E2MGR_log}    *MType: 12001*     #RIC_E2_SETUP_REQ
    ${e2mgr_12002} =     Get Match Count    ${E2MGR_log}    *MType: 12002*     #RIC_E2_SETUP_RESP
    Log To Console       \nNumber of RIC_E2_SETUP_REQ(12001) messages received on E2Mgr: ${e2mgr_12001}
    Log To Console       Number of RIC_E2_SETUP_RESP(12002) messages sent by E2Mgr: ${e2mgr_12002}
    Set Global Variable    ${e2mgr_12001}
    Set Global Variable    ${e2mgr_12002}

RetriveLog From SubMgr
    [Documentation]      RetriveLog From SubMgr
    ${submgrpodname} =   Run Keyword     RetrievePodsForDeployment    deployment-ricplt-submgr    namespace=ricplt
    ${submgr_pod1} =     Set Variable     ${submgrpodname[0]}
    ${submr_log} =       Run keyword    RetrieveLogForPod    ${submgr_pod1}     namespace=ricplt
    ${submgr_12010} =    Get Match Count    ${submr_log}    *MSG from XAPP*    #RIC_SUB_REQ
    ${submgr_12011} =    Get Match Count    ${submr_log}    *MSG to XAPP*      #RIC_SUB_RESP
    Log To Console       \nNumber of RIC_SUB_REQ(12010) received on SubMgr: ${submgr_12010}
    Log To Console       Number of RIC_SUB_RESP(12011) sent by SugMgr: ${submgr_12011}
    Set Global Variable  ${submgr_12010}
    Set Global Variable  ${submgr_12011}

RetriveLog From BouncerxApp
    [Documentation]     RetriveLog From BouncerxApp
    ${podname} =        Run Keyword     RetrievePodsForDeployment       ${GLOBAL_XAPP_DEPLOYMENT}      namespace=ricxapp
    ${ric_xapp_pod1} =  Set Variable    ${podname[0]}
    ${xapp_log} =       Run keyword     RetrieveLogForPod       ${ric_xapp_pod1}       namespace=ricxapp
    ${xapp_12010} =     Get Match Count   ${xapp_log}    *Transmitted subscription request*                     #RIC_SUB_REQ
    ${xapp_12011} =     Get Match Count   ${xapp_log}    *Received subscription message of type = 12011*        #RIC_SUB_RESP
    ${xapp_12050} =     Get Match Count   ${xapp_log}    *Received indication message of type = 12050*          #RIC_INDICATION
    ${xapp_12040} =     Get Match Count   ${xapp_log}    *RMR Return to Sender Message of Type: 12040*          #RIC_CONTROL_REQ
    ${xapp_12041} =     Get Match Count   ${xapp_log}    *RMR Return to Sender Message: Bouncer Control OK*     #RIC_CONTROL_ACK
    Log To Console      \nNumber of RIC_SUB_REQ(12010) messages sent by xApp: ${xapp_12010}
    Log To Console      Number of RIC_SUB_RESP(12011) messages received on xApp: ${xapp_12011}
    Log To Console      Number of RIC_INDICATION(12050) messages received on xApp: ${xapp_12050}
    Log To Console      Number of RIC_CONTROL_REQ(12040) messages sent by xApp: ${xapp_12040}
    Log To Console      Number of RIC_CONTROL_ACK(12041) messages received on xApp: ${xapp_12041}
    Set Global Variable    ${xapp_12010}
    Set Global Variable    ${xapp_12011}
    Set Global Variable    ${xapp_12050}
    Set Global Variable    ${xapp_12040}
    Set Global Variable    ${xapp_12041}

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
     ${count} =     Count Values In List    ${list_count}    CONNECTED
     [Return]          ${count}

Run SubMgr GET Request
     [Documentation]  Runs SubMgr GET Request
     [Arguments]      ${data_path}
     ${auth} =       Create List
     ...              ${GLOBAL_INJECTED_SUBMGR_USER}
     ...              ${GLOBAL_INJECTED_SUBMGR_PASSWORD}
     ${session} =    Create Session  submgr  ${SUBMGR_ENDPOINT}  auth=${auth}
     ${uuid} =       Generate UUID
     ${headers} =    Create Dictionary
     ...              Accept=application/json
     ...              Content-Type=application/json
     ${resp} =       Get Request     submgr   ${data_path}       headers=${headers}
     Log             Received response from SubMgr ${resp.text}
     Should Be True  ${resp}
     [Return]        ${resp}

Count gNB Subscription Success on SubMgr
     [Documentation]   Count gNB Subscription Success on SubMgr
     ${data_path} =    Set Variable             ${SUBMGR_BASE_PATH}/subscriptions
     ${resp} =         Run SubMgr GET Request     ${data_path}
     ${list_sub} =     Set Variable    ${resp.json()}
     ${list_count} =   Create List
     FOR    ${item}    IN    @{list_sub}
         ${ranName} =   Get From Dictionary    ${item}    Meid
         Append To List    ${list_count}     ${ranName}
     END
     ${count} =        Get Length   ${list_count}
     [Return]          ${count}



*** Test Cases ***
###########################################################################################
# Multiple E2SIM - Testing Prepareation                                                    #
###########################################################################################
TC.01 - Ensure Helm3 is installed
    ${input}=       Write       helm version
    ${output}=      Read        delay=0.5s
    Should Contain      ${output}       Version:"v3.7.1"

TC.02 - Deploy E2SIM
    ${input}=       Write    cd ~/test/ric_benchmarking/e2-interface/e2sim/e2sm_examples/kpm_e2sm/helm
    ${output}=      Read     delay=0.5s
    ${input}=       Write       helm install e2sim --namespace test .
    ${resp}=       Read        delay=3s
    Should Contain      ${resp}       deployed
    Sleep       15s

TC.03 - Ensure E2SIM is deployed and available
    [Tags]  multi_e2sim_e2e
    ${ctrl} =   Run Keyword     deployment      ${Global_RAN_DEPLOYMENT}        ${Global_RAN_NAMESPACE}
    Should Be Equal      ${ctrl.status.replicas}          ${ctrl.status.ready_replicas}

TC.04 - RIC xApp Onboarder is deployed and available
    [Tags]  multi_e2sim_e2e
    ${controllerName} =     Set Variable    ${GLOBAL_TEST_XAPP_ONBOARDER}
    ${cType}  ${name} =     Split String    ${controllerName}   \|
    ${ctrl} =  Run Keyword      ${cType}        ${name}
    Should Be Equal      ${ctrl.status.replicas}          ${ctrl.status.ready_replicas}

TC.05 - Deploy Bouncer xApp
    [Tags]  multi_e2sim_e2e
#    Deploy XApp       ${TEST_XAPPNAME}
    ${input}        Write           cd /home/phuong/Documents/nanobot
    ${output}       Read            delay=0.5s
    ${input}        Write           ./auto_deploy_xapp.sh
    ${output}       Read            delay=10s

TC.06 - Wait For Internal Processes
    [Tags]   multi_e2sim_e2e
    #Bouncer xApp will start to send RIC_SUB_REQ messages after deployed 100s
    #Bouncer xApp will send RIC_SUB_REQ messages to SubMgr one by one every 16s
    ${wait_for_xapp_ready} =       Set Variable   100
    ${wait_for_xapp_process} =     Evaluate   ${GLOBAL_TOTAL_NODEB} * 16
    Log To Console    \nPlease wait ...............................................
    Sleep     ${wait_for_xapp_ready}
    Sleep     ${wait_for_xapp_process}


############################################################################################
# Multiple E2SIM - E2 Setup procedure verification between E2SIM and RICPLT                #
############################################################################################

TC.07 - RetriveLog From E2SIM
     [Tags]   multi_e2sim_e2e
     RetriveLog From E2SIM

TC.08 - RetriveLog From E2Mgr
     [Tags]   multi_e2sim_e2e
     RetriveLog From E2Mgr
TC.09 - Count E2 Setup Success
     [Tags]   multi_e2sim_e2e
     ${count_gnb_connected} =    Count gNB in Connected Status on E2Mgr
     Log To Console   \nTotal deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
     Log To Console   Total gNodeB in CONNECTED status: ${count_gnb_connected}
     Set Global Variable    ${count_gnb_connected}
     Should Be Equal As Strings    ${count_gnb_connected}    ${GLOBAL_TOTAL_NODEB}

TC.10 - Count E2 Setup Request messages sent by E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console     \nNumber of deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
     Log To Console     Number of E2 Setup Request messages sent by E2SIM: ${e2sim_12001}
     Should Be Equal As Strings    ${e2sim_12001}    ${GLOBAL_TOTAL_NODEB}

TC.11 - Count E2 Setup Request messages received on E2Mgr
     [Tags]   multi_e2sim_e2e
     Log To Console     \nNumber of E2 Setup Request messages sent by E2SIM: ${e2sim_12001}
     Log To Console     Number of E2 Setup Request messages received on E2Mgr: ${e2mgr_12001}
     Should Be Equal As Strings    ${e2mgr_12001}    ${e2sim_12001}

TC.12 - Count E2 Setup Response messages sent by E2Mgr
     [Tags]   multi_e2sim_e2e
     Log To Console     \nNumber of E2 Setup Request messages received on E2Mgr: ${e2mgr_12001}
     Log To Console     Number of E2 Setup Response messages sent by E2Mgr: ${e2mgr_12002}
     Should Be Equal As Strings    ${e2mgr_12001}    ${e2mgr_12002}

TC.13 - Count E2 Setup Response messages received on E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console     \nNumber of E2 Setup Response messages sent by E2Mgr: ${e2mgr_12002}
     Log To Console     Number of E2 Setup Response messages received on E2SIM: ${e2sim_12002}
     Should Be Equal As Strings    ${e2sim_12002}    ${e2mgr_12002}


############################################################################################
# Multiple E2SIM - Subscription procedure verification between Bouncer xApp and E2SIM      #
############################################################################################
TC.14 - RetriveLog From SubMgr
    [Tags]   multi_e2sim_e2e
    RetriveLog From SubMgr

TC.15 - RetriveLog From BouncerxApp
    [Tags]  multi_e2sim_e2e
    RetriveLog From BouncerxApp

TC.16 - Count Subscription Success
#     [Tags]   multi_e2sim_e2e
#	 ${count_sub_success} =    Count gNB Subscription Success on SubMgr
#	 Set Global Variable       ${count_sub_success}
#     Log To Console   \nTotal deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
#     Log To Console   Total gNodeB Subscription success in SubMgr: ${count_sub_success}
#	 Should Be Equal As Strings    ${count_sub_success}    ${GLOBAL_TOTAL_NODEB}
     ${input}               Write       kubectl get pods -A
     ${resp}                Read        delay=2s
     ${match}               ${pod}      Should Match Regexp         ${resp}         (deployment-ricplt-submgr.\\w+.\\w+)
     ${input}               Write       kubectl exec -t -n ricplt ${pod} -- cat /etc/hosts
     ${output}              Read        delay=3s
     ${resp}                Get Regexp Matches          ${output}           (\\d+.\\d+.\\d+.\\d+).*?(submgr)      1         2
     ${output}               Convert To String           ${resp}
     ${match}               ${submgr_ip}        should match regexp         ${output}      (\\d+.\\d+.\\d+.\\d+)
     ${curl}                Set Variable       curl -X GET "http://${submgr_ip}:8088/ric/v1/subscriptions"
     ${resp}                Execute Command     ${curl}     Read        delay=3s
     ${output}              Convert To String          ${resp}
     ${list_gnb}            Create List
     ${list_gnb}            Get Regexp Matches          ${output}      (gnb.\\w+)          1
     ${count_sub_success}        Get Length             ${list_gnb}
     Set Global Variable       ${count_sub_success}
     Log To Console   \nTotal deployed E2SIM: ${GLOBAL_TOTAL_NODEB}
     Log To Console   Total gNodeB Subscription success in SubMgr: ${count_sub_success}
     Should Be Equal As Strings    ${count_sub_success}    ${GLOBAL_TOTAL_NODEB}

TC.17 - Count RIC Subscription Request messages sent by xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of Connected gNB: ${count_gnb_connected}
     Log To Console    Number of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Should Be Equal As Strings    ${count_gnb_connected}    ${xapp_12010}

TC.18 - Count RIC Subscription Request messages received on SubMgr
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Log To Console    Number of RIC Subscription Request Received on SubMgr: ${submgr_12010}
     Should Be Equal As Strings    ${submgr_12010}    ${xapp_12010}

TC.19 - Count RIC Subscription Response messages sent by SubMgr
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Subscription Request Received from xApp: ${submgr_12010}
     Log To Console    Number of RIC Subscription Response Received on xApp: ${submgr_12011}
     Should Be Equal As Strings    ${submgr_12010}    ${submgr_12011}

TC.20 - Count RIC Subscription Response messages received on xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Subscription Response Sent by SubMgr: ${submgr_12011}
     Log To Console    Number of RIC Subscription Response Received on xApp: ${xapp_12011}
     Log To Console    Number of RIC Subscription Request Sent by xApp: ${xapp_12010}
     Should Be Equal As Strings    ${submgr_12011}    ${xapp_12011}
     Should Be Equal As Strings    ${xapp_12010}    ${xapp_12011}

TC.21 - Count RIC Indication messages sent by E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of gNB Subscription Success on SubMgr: ${count_sub_success}
     Log To Console    Number of RIC Indication Sent by E2SIM: ${e2sim_12050}
     Should Be Equal As Strings    ${count_sub_success}    ${e2sim_12050}

TC.22 - Count RIC Indication messages received on xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Indication Sent by E2SIM: ${e2sim_12050}
     Log To Console    Number of RIC Indication Received on xApp: ${xapp_12050}
     Should Be Equal As Strings    ${xapp_12050}    ${e2sim_12050}

TC.23 - Count RIC Control messages sent by xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Control messages Sent by xApp: ${xapp_12040}
     Log To Console    Number of RIC Indication messages Received on xApp: ${xapp_12050}
     Should Be Equal As Strings    ${xapp_12040}    ${xapp_12050}

TC.24 - Count RIC Control messages received on E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Control messages Sent by xApp: ${xapp_12040}
     Log To Console    Number of RIC Control messages Received on E2SIM: ${e2sim_12040}
     Should Be Equal As Strings    ${xapp_12040}    ${e2sim_12040}

TC.25 - Count RIC Control ACK messages sent by E2SIM
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Control messages Received on E2SIM: ${e2sim_12040}
     Log To Console    Number of RIC Control ACK messages Sent by E2SIM: ${e2sim_12041}
     Should Be Equal As Strings    ${xapp_12040}    ${e2sim_12041}

TC.26 - Count RIC Control ACK messages received on xApp
     [Tags]   multi_e2sim_e2e
     Log To Console    \nNumber of RIC Control ACK messages Sent by E2SIM: ${e2sim_12041}
     Log To Console    Number of RIC Control ACK messages Received on xApp: ${xapp_12041}
     Should Be Equal As Strings    ${e2sim_12041}    ${xapp_12041}

TC.27 - Max Diff Time between Indication and Control messages
     [Tags]   multi_e2sim_e2e
     Log To Console    \nMax Diff Time between Indication and Control messages(Nanosecond): ${e2sim_12050_12040_max}

TC.28 - Min Diff Time between Indication and Control messages
     [Tags]   multi_e2sim_e2e
     Log To Console    \nMin Diff Time between Indication and Control messages(Nanosecond): ${e2sim_12050_12040_min}

TC.29 - Undeploy E2sim
    ${input}        Write           cd /home/phuong/Documents/nanobot
    ${output}       Read            delay=0.5s
    ${input}        Write           ./auto_undeploy_e2sim.sh
    ${output}       Read            delay=10s

TC.30 - Undeploy The Deployed XApp
    [Tags]   multi_e2sim_e2e
#    Undeploy XApp     ${TEST_XAPPNAME}
#    ${input}        Write           cd /home/phuong/Documents/nanobot
#    ${output}       Read            delay=0.5s
#    ${input}        Write           ./auto_undeploy_xapp.sh
#    ${ouput}        Read            delay=5s
    ${input}         Write      curl -v -X POST "http://10.100.136.133:8080/ric/v1/deregister" -H "accept: application/json" -H "Content-Type: application/json" -d '{"appName": "bouncer-xapp", "appInstanceName": "bouncer-xapp"}'
    ${output}        Read       delay=3s
    ${input}         Write      curl -X DELETE http://0.0.0.0:8090/api/charts/bouncer-xapp/2.0.0
    ${output}        Read       delay=2s
    ${input}         Write      dms_cli uninstall bouncer-xapp ricxapp
    ${output}        Read       delay=5s

