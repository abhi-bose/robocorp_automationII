*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive


*** Variables ***
${CUSTOM_TIMEOUT}                   10s
${PDF_TEMP_OUTPUT_DIRECTORY} =      ${OUTPUT_DIR}${/}temp
${PDF_TEMPLATE_PATH} =              ${OUTPUT_DIR}${/}mergedpdfs


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set Direcrories
    Open the robot order website
    Download Excel File
    Open csv and set data
    Create ZIP package from PDF files
    [Teardown]    Clean up resources


*** Keywords ***
Set Direcrories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Create Directory    ${PDF_TEMPLATE_PATH}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Download Excel File
    Download    https://robotsparebinindustries.com/orders.csv

Open csv and set data
    ${order_data} =    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{order_data}
        Place order    ${order}
    END

Wait for page loading
    Wait Until Page Contains Element    css:button.btn-dark
    Click Button    css:button.btn-dark
    Wait Until Page Contains Element    class:main-container
    Element Should Be Visible    id:preview
    Element Should Be Visible    id:order

Place order
    [Arguments]    ${order}
    Wait for page loading
    Select From List By Value    css:select.custom-select    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[type=number]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:order
    ${img} =    Snapshot image    ${order}[Order number]
    ${pdf} =    Export receipt as PDF    ${order}[Order number]
    Embed screenshot to the pdf    ${order}[Order number]    ${img}    ${pdf}
    Sleep    1
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Snapshot image
    [Arguments]    ${order_id}
    ${img_name} =    Catenate    ${order_id}    robot-image.png
    Sleep    1
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${img_name}
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${img_name}

Export receipt as PDF
    [Arguments]    ${order_id}
    ${passed} =    Run Keyword And Return Status    Wait Until Element Is Visible    id:receipt
    WHILE    ${passed} == False
        IF    ${passed} == False    Click Button    id:order
        ${passed} =    Run Keyword And Return Status    Wait Until Element Is Visible    id:receipt
    END
    Wait Until Element Is Visible    id:receipt
    ${receipt} =    Get Element Attribute    id:receipt    outerHTML
    ${pdf_name} =    Catenate    ${order_id}    receipt.pdf
    Html To Pdf    ${receipt}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${pdf_name}
    RETURN    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${pdf_name}

Embed screenshot to the pdf
    [Arguments]    ${order_id}    ${img}    ${pdf}
    ${files} =    Create List    ${pdf}    ${img}
    ${pdf_name} =    Catenate    ${order_id}    final_receipt.pdf
    Add Files To Pdf    ${files}    ${PDF_TEMPLATE_PATH}${/}${pdf_name}

Create ZIP package from PDF files
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${PDF_TEMPLATE_PATH}    ${zip_file_name}

Clean up resources
    Close Browser
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True


