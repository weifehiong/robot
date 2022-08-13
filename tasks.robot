*** Settings ***
Documentation       Robot course - II
...                 Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             Collections
Library             RPA.Robocorp.Vault
Library             String
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
# Library    OperatingSystem


*** Variables ***
${web_url}                      https://robotsparebinindustries.com/#/robot-order
# ${csv_url}    https://robotsparebinindustries.com/orders.csv
${csv_path}                     orders.csv

${locator_robot_preview}        xpath://*[@id="robot-preview-image"]

${locator_receipt}              xpath://*[@id="receipt"]
${locator_receipt_title}        xpath://*[@id="receipt"]/h3
${locator_receipt_timeZone}     xpath://*[@id="receipt"]/div[1]
${locator_receipt_badge}        xpath://*[@id="receipt"]/p[2]
${locator_receipt_parts}        xpath://*[@id="parts"]
${locator_receipt_footer}       xpath:/html/body/div/div/div[1]/div/div[1]/div/div/p[3]
${locator_submit_error}         xpath:/html/body/div/div/div[1]/div/div[1]/div
# ${time_now}    Get Time    time_=Now    %d.%m.%Y    #format=%Y-%m-%d.%H-%M#%d.%m.%Y %H:%M


*** Tasks ***
# Log out directory
#    [Tags]    test
#    Log To Console    ${OUTPUT_DIR}
#    # ${OUTPUT_DIR}
#    Log To Console    ${OUTPUT_DIR}${/}output${/}screenshot
#    Log To Console    ${OUTPUT_DIR}${/}screenshot

# Set Screenshot Directory    ${OUTPUT_DIR}${/}output${/}screenshot
# Collect url of order from user
#    ${url}    Collect url of order from user
#    Log To Console    ${url}

Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}    Get orders
    FOR    ${element}    IN    @{orders}
        # Log    ${element}[Head]
        Log Many
        ...    Order number:${element}[Order number]
        ...    Head:${element}[Head]
        ...    Body:${element}[Body]
        ...    Legs:${element}[Legs]
        ...    Address:${element}[Address]
        ...    level=Warn

        fill the form with a row of data
        ...    ${element}[Head]
        ...    ${element}[Body]
        ...    ${element}[Legs]
        ...    ${element}[Address]
        # sleep a little
        ${screenShot}    Take a screenshot of the robot    ${element}[Order number]

        Submit the order
        ${pdf}    Store the order receipt as a PDF file by outHTML    ${element}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenShot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser

# Append file_list to pdf
#    ${list_files}    Create List    output/screenshot/*.png
#    Log To Console    ${list_files}
#    # Add Files To Pdf    files=${list_files}    append=True    target_document=1.pdf


*** Keywords ***
Open the robot order website
    ${secret}    Get Secret    web_url
    Open Browser    ${secret}[url_robot_order]    browser=firefox
    Maximize Browser Window
    ${title}    Get Title
    Log    ${title}

Close the annoying modal
    [Documentation]    Click OK button to make the dialog disappear
    # Handle Alert    action=accept
    # Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    # Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Click Element If Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Collect url of order from user
    [Documentation]    获取用户输入的下载订单链接
    Add text input    URL_of_Order    label=The url to requesting order
    ${url_response}    Run dialog
    RETURN    ${url_response.URL_of_Order}

Get orders
    [Documentation]    Download csv file through Download method of http Library
    # https://robotsparebinindustries.com/orders.csv
    ${csv_url}    Collect url of order from user
    Download    ${csv_url}    ${csv_path}    overwrite=True
    ${orders}    Read table from CSV    ${csv_path}    header=True
    ${rows_orders}    Get Length    ${orders}
    Log    Orders count:${rows_orders}
    RETURN    @{orders}

fill the form with a row of data
    [Arguments]    ${head}=3    ${body}=2    ${legs}=2    ${address}='Robot designed by WEIFH'
    # Scroll Element Into View    xpath://*[@id="preview"]
    # Highlight Elements    id:head    color=Red    width=5px
    Select From List By Value    id:head    ${head}
    Click Element    css:#id-body-${body}    #click the second Radio button
    Input Text    xpath://*[@class='form-control'][@type='number']    ${legs}
    Input Text    xpath://*[@id='address']    ${address}
    Preview the robot

Preview the robot
    [Documentation]    Preview the robot and wait untill pic is visible
    Click Element    xpath://*[@id="preview"]    #id:preview
    Wait Until Element Is Visible    ${locator_robot_preview}
    # Highlight element with dotted    ${locator_robot_preview}
    # sleep a little    2s

Submit the order
    [Documentation]    Submit the order
    # Click Element    xpath://*[@id="order"]    #id:order
    # Highlight element with dotted    xpath://*[@id="order"]

    # Click Element If Visible    xpath://*[@id="order"]
    # Run Keyword And Continue On Failure    Retry submit
    # Does Page Contain Element返回true or False
    ${contain_receipt}    Does Page Contain Element    ${locator_receipt}
    # Log    ！！！捕获到网页异常信息：${count_errInfo}
    WHILE    ${contain_receipt}==${False}
        Click Element    xpath://*[@id="order"]
        ${contain_receipt}    Does Page Contain Element    ${locator_receipt}
    END

    # 案例中用的是    Wait Until Keyword Succeeds
    #    Wait Until Keyword Succeeds    retry    retry_interval    name
    #    Examples:

    # Wait Until Keyword Succeeds    2 min    5 sec    My keyword    argument
    # ${result} =    Wait Until Keyword Succeeds    3x    200ms    My keyword
    # ${result} =    Wait Until Keyword Succeeds    3x    strict: 200ms    My keyword

    # IF    ${count_errInfo}==${True}    Retry submit    ELSE    Skip
    # WHILE    ${count_errInfo}
    #    Retry submit
    # END
    # IF    ${count_errInfo} == True    Retry submit    ELSE    Skip
    #<button id="order" type="submit" class="btn btn-primary">Order</button>
    # Highlight element with dotted    ${locator_receipt}
    # Highlight element with dotted    ${locator_robot_preview}
    # sleep a little

    # Element Should Not Be Visible    ${locator_submit_error}    #判断Order时是否出现服务异常
    # Order后捕获异常：如果异常没有出现，则执行后续任务；如果捕获到异常，则持续点击Order
    # ${errInfo_submit}    Element Should Not Be Visible    ${locator_submit_error}
    # IF    ${errInfo_submit}!=None    Submit the order

    # ${text_err_info}    Get Text    ${locator_submit_error}
    # WHILE    ${text_err_info} != ""
    #    Click Element If Visible    xpath://*[@id="order"]
    # END

Retry submit
    ${count_errInfo}    Does Page Contain Element    ${locator_submit_error}
    WHILE    ${count_errInfo} == True
        Click Element If Visible    xpath://*[@id="order"]
        ${count_errInfo}    Does Page Contain Element    ${locator_submit_error}
    END
    # Click Element If Visible    xpath://*[@id="order"]

Veryfi order_error_info
    ${count_errInfo}    Does Page Contain Element    ${locator_submit_error}
    RETURN    ${count_errInfo}

fill the form with an augument
    [Arguments]    ${list_table}
    Log To Console    ${list_table}
    # 获取head
    ${order_head}    ${list_table}[Head]
    ${order_head}    Convert To Number    ${order_head}
    Select From List By Value    id:head    ${order_head}
    #获取body数量
    ${id_body}    Convert To String    ${list_table}[Body]    #No keyword with name '${list_table}[Body]' found.
    ${css_body}    Catenate    css:#id-body-    ${list_table}[Body]
    Click Element    ${css_body}    #css:#id-body-3
    #获取legs数量
    ${order_legs}    ${list_table}[Legs]
    ${order_legs}    Convert To Integer    ${order_legs}
    Input Text    xpath://*[@class='form-control'][@type='number']    ${order_legs}
    #获取address
    ${order_address}    ${list_table}[Address]
    ${order_address}    Convert To Title Case    ${order_address}
    Input Text    xpath://*[@id='address']    ${order_address}
    Preview the robot

Get full path of a file by file_name
    [Arguments]    ${file_name_full}
    ${list_path_file}    Find Files    ${file_name_full}
    # 返回列表中第一个匹配的结果
    RETURN    ${list_path_file}

Take a screenshot of the robot
    [Documentation]    Take a screenshot of the robot
    [Arguments]    ${file_name}
    # Set Screenshot Directory    ${OUTPUT_DIR}${/}output${/}screenshot
    Create Directory    ${OUTPUT_DIR}${/}screenshot    parents=True
    # ${directory_screenshot}    Set Screenshot Directory    ${OUTPUT_DIR}${/}output${/}screenshot
    # No such file or directory: 'EMBED//1.png'
    #filename=screenshot/${file_name}.png
    Screenshot
    ...    locator=${locator_robot_preview}
    ...    filename=${OUTPUT_DIR}${/}screenshot${/}${file_name}.png
    # ${path_screenshot_full}    Get full path of a file by file_name    ${file_name}.png
    # Log Many    ${file_name}    ${path_screenshot_full}
    # sleep a little    2s
    # ${file_name}=${file_name}.png
    RETURN    ${file_name}

Deleted:Store the order receipt as a PDF file
    [Documentation]    output to pdf file
    [Arguments]    ${pdf_file_name}
    ${receipt_title}    Get Text    ${locator_receipt_title}
    ${receipt_timeZone}    Get Text    ${locator_receipt_timeZone}
    ${receipt_badge}    Get Text    ${locator_receipt_badge}
    ${receipt_parts}    Get Text    ${locator_receipt_parts}
    ${receipt_footer}    Get Text    ${locator_receipt_footer}
    Log    ${receipt_title}
    Log    ${receipt_timeZone}
    Log    ${receipt_badge}
    Log    ${receipt_parts}
    Log    ${receipt_footer}
    # Example:
    # *** Tasks ***
    # Create a new file
    #    ${content}=    Get    url=https://www.example.com
    #    Create file    output/newfile.html    content=${content.text}
    #    ...    overwrite=${True}
    # ${pdf_file}    Get File Name    ${pdf_file_name}
    ${pdf_file}    Create File
    ...    path=${OUTPUT_DIR}${/}receipts/${pdf_file_name}.pdf
    ...    encoding=utf-8
    ...    content=${receipt_title} #${receipt_timeZone} ${receipt_badge} ${receipt_parts} ${receipt_footer}
    ...    overwrite=True
    RETURN    ${pdf_file}

Store the order receipt as a PDF file by outHTML
    [Arguments]    ${pdf_file_name}
    ${receipt_visable}    Element Should Be Visible    ${locator_receipt}
    Log    ${receipt_visable}
    ${receipt_HTML}    Get Element Attribute    ${locator_receipt}    outerHTML
    Html To Pdf    ${receipt_HTML}    ${OUTPUT_DIR}${/}receipts/${pdf_file_name}.pdf
    RETURN    ${pdf_file_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot_name}    ${pdf_file}
    # ${list_file}    Create List    ${file_name}
    # Add Files To Pdf    ${list_file}    ${new_pdf_file}    append=True
    # ${list_screenshot}    Get full path of a file by file_name    ${screenshot_name}
    Create Directory    ${OUTPUT_DIR}${/}receipts    # 创建一个目录
    ${list_file}    Create List    ${OUTPUT_DIR}${/}screenshot/${screenshot_name}.png
    Add Files To Pdf    ${list_file}    target_document=${OUTPUT_DIR}${/}receipts/${pdf_file}.pdf    append=True

Go to order another robot
    Click Element If Visible    xpath://*[@type="submit"]    #点击Order按钮
    #<button id="order-another" type="submit" class="btn btn-primary">Order another robot</button>
    Close the annoying modal

Highlight element with dotted
    [Arguments]    ${locator}
    Highlight Elements    ${locator}    width=5px    color=red

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    receipts.Zip

sleep a little
    [Arguments]    ${duration}=1s
    Sleep    ${duration}
