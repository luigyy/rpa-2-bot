*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop.OperatingSystem
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      6x
${GLOBAL_RETRY_INTERVAL}    0.2s
${PDF_OUTPUT_DIRECTORY}=    ${CURDIR}${/}pdfs


*** Tasks ***
Order robots from RobotSpareBin and create ZIP of the receipts
    Set up directories
    Open browser and go to the site
    Accept the alert message
    Fill and Submit the form for all of the orders
    Create ZIP package from PDF files
    [Teardown]    Close browser cleanup


*** Keywords ***
Open browser and go to the site
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Accept the alert message
    Wait Until Element Is Visible    class:btn-dark
    Click Button    class:btn-dark

Fill and Submit the form for all of the orders
    ${orders}=    Download the data sheet and read it as a table
    FOR    ${order}    IN    @{orders}
        Fill and Submit the form for one order    ${order}
        Take screenshot of the robot image    ${order}
        ##wait until button works
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Click button to order
        Create the pdf of the receipt    ${order}
        Open pdf and add attach the robot image to it    ${order}
        Click to go to another order
    END

#
#
# nested
#
#

Set up directories
    Create Directory    ${PDF_OUTPUT_DIRECTORY}

Download the data sheet and read it as a table
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    # read csv as table
    ${orders_data}=    Read table from CSV    orders.csv
    RETURN    ${orders_data}

# columns=['Order number', 'Head', 'Body', 'Legs', 'Address']

Fill and Submit the form for one order
    [Arguments]    ${order}
    Wait Until Element Is Visible    class:form-group
    #fill form
    Select From List By Value    head    ${order}[Head]
    Click Button    id-body-${order}[Body]
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]

Take screenshot of the robot image
    [Arguments]    ${order}
    #before submitting, take screenshot of the robot
    Click Button    preview
    Wait Until Element Is Visible    css:div#robot-preview-image
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}order-${order}[Order number].png

Click button to order
    #order
    Click Button    order
    Wait Until Element Is Visible    receipt

Create the pdf of the receipt
    [Arguments]    ${order}
    #before making another order, create pdf receipt
    ${receipt_element}=    Get Element Attribute    css:div#receipt    outerHTML
    Html To Pdf    ${receipt_element}    ${PDF_OUTPUT_DIRECTORY}${/}order-${order}[Order number].pdf

Open pdf and add attach the robot image to it
    [Arguments]    ${order}
    ${robot_image}=    Create List    ${OUTPUT_DIR}${/}order-${order}[Order number].png
    Add Files To Pdf
    ...    ${robot_image}
    ...    ${PDF_OUTPUT_DIRECTORY}${/}order-${order}[Order number].pdf
    ...    append=True

Click to go to another order
    #click to make another order
    Click Button When Visible    id:order-another
    #
    Accept the alert message

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Close browser cleanup
    Close Browser
