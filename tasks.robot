*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             OperatingSystem
Library             RPA.Robocorp.Vault
# Library    RPA.Robocloud.Secrets


*** Variables ***
${MAX_ATTEMPTS}=    5


*** Tasks ***
Open browser
    ${secret}=    Get Secret    credentials
    Open Chrome Browser    ${secret}[RPA_URL]
    # Open the robot order website

Order robots from RobotSpareBin Industries Inc
    Download orders file
    ${orders}=    Get orders

    FOR    ${row}    IN    @{orders}
        Close the popup
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close The Browser


*** Keywords ***
# Open the robot order website
#    Open Available Browser    ${secret}[RPA_URL]

Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the popup
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Set Local Variable    ${orderNum}    ${row}[Order number]
    Set Local Variable    ${head}    ${row}[Head]
    Set Local Variable    ${body}    ${row}[Body]
    Set Local Variable    ${legs}    ${row}[Legs]
    Set Local Variable    ${address}    ${row}[Address]

    Select From List By Index    head    ${head}
    Select Radio Button    body    ${body}
    Input with XPath    //input[@placeholder="Enter the part number for the legs"]    ${legs}
    Input with XPath    //input[@placeholder="Shipping address"]    ${Address}

Input with XPath
    [Arguments]    ${xpath}    ${value}
    ${result}=    Execute Javascript
    ...    document.evaluate('${xpath}',document.body,null,9,null).singleNodeValue.value='${value}';
    RETURN    ${result}

Preview the robot
    Click Button    css:#preview

Submit the order
    Click Button    css:#order
    FOR    ${i}    IN RANGE    ${MAX_ATTEMPTS}
        ${found}=    Run keyword And Return Status    Wait Until Element Is Visible    id:receipt
        IF    ${found} == True
            IF    True    BREAK
        ELSE
            Click Button    id:order
            Sleep    1
        END
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNum}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}recipt_${orderNum}.pdf
    RETURN    ${CURDIR}${/}output${/}recipt_${order_num}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNum}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}image_${orderNum}.pdf
    RETURN    ${CURDIR}${/}output${/}image_${orderNum}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To PDF    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}    coverage=0.2
    # Close Pdf    ${pdf}

Go to order another robot
    Click Button    css:#order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    ${CURDIR}${/}output${/}receipts.zip    include=*.pdf

Close The Browser
    Close Browser
