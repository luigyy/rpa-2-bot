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


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      5x
${GLOBAL_RETRY_INTERVAL}    0.5s


*** Tasks ***
Order robots from RobotSpareBin and create ZIP of the receipts
    Open browser and go to the site
    Accept the alert message
    Fill and Submit the form for all of the orders


*** Keywords ***
Open browser and go to the site
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Accept the alert message
    Wait Until Element Is Visible    class:btn-dark
    Click Button    class:btn-dark

Fill and Submit the form for all of the orders
    ${orders}=    Download the data sheet and read it as a table
    FOR    ${order}    IN    @{orders}
        #sometimes button wont work
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Fill and Submit the form for one order    ${order}
    END

#
#
# nested
#
#

Download the data sheet and read it as a table
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    # read csv as table
    ${orders_data}=    Read table from CSV    orders.csv
    RETURN    ${orders_data}

# columns=['Order number', 'Head', 'Body', 'Legs', 'Address']

Fill and Submit the form for one order
    [Arguments]    ${order}
    Wait Until Element Is Visible    class:form-group
    #
    Select From List By Value    head    ${order}[Head]
    Click Button    id-body-${order}[Body]
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    order
    #
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    #
    Accept the alert message
