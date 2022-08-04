#   Copyright (c) 2019 AT&T Intellectual Property.
#   Copyright (c) 2020 HCL Technologies Ltd. 
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

*** Settings ***
Documentation      Run basic health checks for all known components which have one
Resource           /robot/resources/global_properties.robot
Resource           /robot/resources/ric/ric_utils.robot
Library  KubernetesEntity  ${GLOBAL_RICPLT_NAMESPACE} 
Library  Collections 
Library  String 
Library  Process 
Library  OperatingSystem
Library           RequestsLibrary
Library           UUID
Library           StringTemplater
Library           SSHLibrary
Library           PyShark
Library           Selenium2Library


Suite Setup       SSH to OS with ROOT
Suite Teardown    Close All Connections

*** Keywords ***
Health Check For Pod Using DMS_CLI
    [Arguments]    ${pod_name}
    SSH to OS with ROOT
    ${input}            Write           dms_cli health_check ${pod_name} ricplt
    ${output}           Read            delay=3s
    Should Contain      ${output}       Healthy

SSH to OS with ROOT
    [Arguments]     ${addr_ip}=${GLOBAL_TERMINAL_IP}        ${user_name}=${GLOBAL_USER_NAME}        ${pass_word}=${GLOBAL_USER_PWD}
    Set Log Level       DEBUG
    Open Connection     ${addr_ip}
    ${output}=           Login       ${user_name}        ${pass_word}
    Should Contain      ${output}     Last login
    Start Command       pwd
    ${pwd}=         Read Command Output
    Should Be Equal     ${pwd}      /home/${user_name}
    ${written} =     Write       sudo su
    ${output} =      Read        delay=0.5s
    ${written} =     Write       ${pass_word}
    ${output} =      Read        delay=0.5s
*** Test Cases ***
Ensure RIC components are deployed and available
  [Tags]  Health-check RIC components
  ${result}=     set variable      True
  FOR   ${component}  IN        @{GLOBAL_RICPLT_COMPONENTS}
     Log To Console     \ncomponent is ${component}
     SSH to OS with ROOT
     ${input}            Write           dms_cli health_check ${component} ricplt
     ${output}           Read            delay=3s
     ${success} =        Run Keyword And Return Status       Should Contain       ${output}         Healthy
     IF     ${success}==False
        Log to console     ${component} is Unhealthy
        ${result}=    set variable           false
        set global variable       ${result}
     ELSE
        Log to console     ${component} is Healthy
     END
  END
  Run Keyword If        '${result}'=='false'
  ...                   log to console      One or more Health Checks Unhealthy

