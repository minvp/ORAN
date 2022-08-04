# Vietnam Team - Nanobot Practices

*** Settings ***
Resource          /robot/resources/e2mgr_interface.robot
Resource          /robot/resources/global_properties.robot
Resource          /robot/resources/json_templater.robot
Library           Collections
Library           String
Library           RequestsLibrary
Library           UUID
Library           StringTemplater
Library           OperatingSystem

*** Variables ***
${E2MGR_BASE_PATH}     v1/nodeb
${E2MGR_SETUP_ENB_TEMPLATE}     /robot/resources/e2mgr_setup_enb.template
*** Keywords ***
# Get E2T address from E2Mgr:
Run E2Mgr Get All E2T Addresses Request
     [Documentation]  Runs E2Mgr Get All E2T Addresses Request
     ${data_path} =   Set Variable               /v1/e2t/list
     ${resp} =        Run E2Mgr GET Request      ${data_path}
     ${list_e2t} =    Set Variable    ${resp.json()}
     ${e2t_adds} =    Create List
     FOR    ${item}    IN    @{list_e2t}
         ${url}    Get From Dictionary    ${item}    e2tAddress
         ${add}    ${port} =   Split String    ${url}    :
         Append To List   ${e2t_adds}    ${add}
     END
     Log To Console    ${e2t_adds}
     [Return]          ${e2t_adds}

# Count gNB in CONNECTED status from E2Mgr:
Run E2Mgr Count gNB in Connected Status Request
     [Documentation]   Run E2Mgr Count gNB in Connected Status Request
     ${data_path} =    Set Variable             ${E2MGR_BASE_PATH}/states
     ${resp} =         Run E2Mgr GET Request    ${data_path}
     ${list_gnb} =        Set Variable    ${resp.json()}
     ${list_count} =         Create List
     FOR    ${item}    IN    @{list_gnb}
         ${status} =   Get From Dictionary    ${item}    connectionStatus
         Append To List    ${list_count}     ${status}
     END
     Log To Console     ${list_count}
     ${count} =     Count Values In List    ${list_count}    CONNECTED
     Log To Console    ${count}
     [Return]          ${count}

Run E2Mgr Get gNodeB Connection Status Request
     [Documentation]  Runs E2Mgr Get NodeB Request
     [Arguments]      ${ran_name}
     ${data_path} =  Set Variable             ${E2MGR_BASE_PATH}/${ran_name}
     ${resp} =       Run E2Mgr GET Request    ${data_path}
     Should Be Equal As Strings               ${resp.json()['ranName']}  ${ran_name}
     Log To Console    ${resp.json()['connectionStatus']}
     Log To Console    ${ran_name}
     [Return]          ${resp.json()['connectionStatus']}

Run E2Mgr Get All gNodeB Name Request
     [Documentation]  Runs E2Mgr Get All NodeB Name Request
     ${data_path} =  Set Variable             ${E2MGR_BASE_PATH}/states
     ${resp} =       Run E2Mgr GET Request    ${data_path}
     ${list_gnb} =        Set Variable    ${resp.json()}
     ${list_ranName} =         Create List
     FOR    ${item}    IN    @{list_gnb}
         Log To Console    ${item}
         ${ranName} =   Get From Dictionary    ${item}    inventoryName
         Append To List    ${list_ranName}     ${ranName}
     END
     Log To Console     ${list_ranName}
     [Return]          ${list_ranName}

Run E2Mgr PUT Request
     [Documentation]    Runs E2Mgr Delete Request
     [Arguments]     ${data_path}
     ${auth} =       Create List
     ...              ${GLOBAL_INJECTED_E2MGR_USER}
     ...              ${GLOBAL_INJECTED_E2MGR_PASSWORD}
     ${session} =    Create Session  e2mgr  ${E2MGR_ENDPOINT}  auth=${auth}
     ${uuid} =       Generate UUID
     ${headers} =    Create Dictionary
     ...              Accept=application/json
     ...              Content-Type=application/json
     ${resp} =       Put Request  e2mgr  ${data_path}       headers=${headers}
     Log             Received response from E2Mgr ${resp.text}
     Should Be True  ${resp}
     [Return]        ${resp}

Run E2Mgr Shutdown All gNodeB Request
    ${data_path} =  Set Variable             ${E2MGR_BASE_PATH}/shutdown
    ${resp} =       Run E2Mgr PUT Request    ${data_path}
    Log to console     ${resp}

Run E2Mgr To Insert New ENB Request
     [Documentation]  Setup X2 NodeB via E2 Manager
     ${data_path} =  Set Variable  ${E2MGR_BASE_PATH}/enb
     ${data} =       Fill JSON Template ENB  ${E2MGR_SETUP_ENB_TEMPLATE}
     ${resp} =       Run E2Mgr POST Request   ${data_path}                   ${data}
     [Return]         ${resp}

Fill JSON Template ENB
    [Documentation]    Runs substitution on template to return a filled in json
    [Arguments]    ${json_file}
    ${json}=    OperatingSystem.Get File    ${json_file}
    ${returned_json}=  To Json    ${json}
    [Return]    ${returned_json}


*** Test Cases ***
# Verify E2T address
Get E2T Via E2Mgr
    [Tags]   e2mgrtests   etetests   e2setup
    ${e2t_adds} =    Run E2Mgr Get All E2T Addresses Request
    Should Contain    ${e2t_adds}    ${GLOBAL_TEST_E2T_ADDRESS}

# Multiple E2SIM - E2 Setup procedure verification:
Multiple E2SIM - E2Setup Verification
     [Tags]   e2mgrtests   etetests   e2setup
     ${count} =    Run E2Mgr Count gNB in Connected Status Request
     Should Be Equal As Strings    ${count}    ${GLOBAL_TOTAL_NODEB}

Get gNodeB Connection Status Request Via E2Mgr
    [Tags]   e2mgrtests   etetests   e2setup
    ${Before} =   Run E2Mgr Get gNodeB Connection Status Request     ${GLOBAL_GNBID}
    Log To Console    ${Before}
    Should Be Equal As Strings     ${Before}   CONNECTED
    Run E2Mgr Shutdown All gNodeB Request
    ${After} =    Run E2Mgr Get gNodeB Connection Status Request    ${GLOBAL_GNBID}
    Log To Console    ${After}
    Should Be Equal As Strings    ${After}   SHUT_DOWN

Insert New ENB Request
    Run E2Mgr To Insert New ENB Request
    ${list_ranName} =    Run E2Mgr Get All gNodeB Name Request
    Should Contain    ${list_ranName}     test_enb4