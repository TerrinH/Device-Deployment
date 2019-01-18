# ongoing-deployment-master
An Excel workbook with a code base I created to track the deployment stages of individual devices for different customers. The workbook 
was designed to function as a template that is used to create working copies that are to be used before archiving at a desired time 
interval. When archiving a working copy there is a subroutine within this workbook that allows it to pull only active data from another
working copy. Archiving working copies at specified time intervals allows us to keep the file size of the workbook manageable and removes
significant amounts of inactive data (shipped devices).


**HOW IT WORKS**:
  The workbook has 5 worksheets; Master, Special Status, Completed, Shipped, and SETTINGS:
  
  - **Master**:
    This is the main worksheet where all the basic device info is entered initially along with the customer name and storage location.
    There is a _Status_ column that allows the user to get a more big-picture view of the various projects and devices per customer. This
    _Status_ column is updated whenever a device's serial number is found on another worksheet, as all worksheets beyond the _Master_
    worksheet are more progressive in their representation of a device's deployment progress.
    
  - **Special Status**:
    When a device is placed in special circumstaces, for whatever reason (such as damage or special configuration), and is separated from
    the forecasted deployment process the other devices are going through, it ends up here to track and record that altered course.
    
  - **Completed**:
    After a device has completed its requested deployment process it will be entered onto this worksheet. The primary function of this
    worksheet is verifying that the correct device is placed in the correct box before shipping. The worksheet primarily compares the
    serial number of the unit against the serial number on the box it is being packaged in, and fetches the model number associated with
    the provided device serial number.
    
  - **Shipped**:
    Once the preliminary quality control of the _Completed_ worksheet has been completed and the device is ready to be packaged in its
    shipping medium, it ends up here where we associate a shipping tracking number with the device.
  
  - **SETTINGS**:
    The _SETTINGS_ worksheet is really just a placeholder for the data validation range I use in the _Special Status_ worksheet, and
    allows the user to modify all the data validation drop-downs in one place.
    
**FURTHER READING**:
  Each worksheet has a significant amount of functionality behind it and a more in-depth guide is required to fully understand and make
  use of this workbook. I will be creating this extended funtionality and usage guide at a later time.
