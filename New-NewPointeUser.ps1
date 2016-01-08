New-Variable -Name NewFirstName
New-Variable -Name NewLastName
New-Variable -Name NewDisplayName
New-Variable -Name NewUserName
New-Variable -Name NewMI
New-Variable -Name NewWorkPhone
New-Variable -Name NewWorkPhoneE164
New-Variable -Name NewWorkPhoneLast4
New-Variable -Name NewMobilePhone
New-Variable -Name NewEmailAddress1
New-Variable -Name NewEmailAddress2
New-Variable -Name NewSupervisor
New-Variable -Name NewSupervisorFullname
New-Variable -Name NewOffice
New-Variable -Name NewDepartment
New-Variable -Name NewJobTitle
New-Variable -Name CreatingLyncAccount
New-Variable -Name CreatingExchangeMailbox
New-Variable -Name NewUPN

#Our primary function. Everything will run from here.
function Primary
{
   #Set variables that we'll need to pass between functions.



   #Import the Active Directory module 
   Import-Module ActiveDirectory

   CollectInfo ([ref]$CreatingExchangeMailbox) ([ref]$CreatingLyncAccount)

   Write-Host "`n"
   $ReadyToGo = Read-Host "Are you ready to do this? (y/n)"
   If ($ReadyToGo -eq "y")
   {
    Write-Host "`nAlright, let's do this!`n" -ForegroundColor Green
    
    CreateADAccount ([ref]$NewUserName) ([ref]$NewFirstName) ([ref]$NewMI) ([ref]$NewLastName) ([ref]$NewDisplayName) ([ref]$NewJobTitle) ([ref]$NewDepartment) ([ref]$NewOffice) ([ref]$NewSupervisor) ([ref]$NewWorkPhone) ([ref]$NewMobilePhone) ([ref]$NewUPN)
    If ($CreatingExchangeMailbox -eq "y")
    {
        CreateExchangeMailbox ([ref]$NewUPN) ([ref]$NewEmailAddress1) ([ref]$NewEmailAddress2)
    }
    If ($CreatingLyncAccount -eq "y") {
        CreateLyncAccount
    }
    If ($CreatingLyncAccount -eq "y") {
        Sleep -Seconds 120
        EnableUM
    }

}
Else
{
    Write-Host "`n"
    Write-Host "Account creation cancelled." -ForegroundColor Red
    Write-Host "`n"
}
}

#This is where we'll collect everything we need to know about the new user.
function CollectInfo ([ref]$CreatingExchangeMailbox, [ref]$CreatingLyncAccount)
{



    #First off, let's get some credentials stored so we can run this stuff.
    #   $scriptcred = Get-Credential


    #Start running functions to collect our info on the new user.

    GetUserName ([ref]$NewFirstName) ([ref]$NewLastName) ([ref]$NewMI) ([ref]$NewDisplayName) ([ref]$NewUserName) ([ref]$NewUPN)
    GetJobTitle ([ref]$NewFirstName) ([ref]$NewJobTitle)
    GetDepartment ([ref]$NewFirstName) ([ref]$NewDepartment)
    GetOffice ([ref]$NewFirstName) ([ref]$NewOffice)
    GetSupervisor ([ref]$NewFirstName) ([ref]$NewSupervisor) ([ref]$NewSupervisorFullname)

    #Check to see if we're making an Exchange Mailbox. If not, then we don't need to ask for email addresses. 
    Do 
    {
        Write-Host "`n"
        Write-Host "Will we be creating an Exchange mailbox for the new user? (Y or N): " -ForegroundColor Yellow -NoNewline
        $CreatingExchangeMailboxChoice = Read-Host
        $CreatingExchangeMailboxChoice = $CreatingExchangeMailboxChoice.ToLower()
    }
    Until ($CreatingExchangeMailboxChoice -eq "y" -or $CreatingExchangeMailboxChoice -eq "n")
    $CreatingExchangeMailbox.Value = $CreatingExchangeMailboxChoice
    If ($CreatingExchangeMailboxChoice -eq "y")
    {
        MakeEmailAddresses ([ref]$NewFirstName) ([ref]$NewLastName) ([ref]$NewMI) ([ref]$NewUserName) ([ref]$NewEmailAddress1) ([ref]$NewEmailAddress2)
    }


    #Check to see if we're creating a Lync account. If not, there's no need to collect phone numbers.
    Do{
        Write-Host "`n"
        Write-Host "Will we be creating a Lync account for this user? (Y or N): " -ForegroundColor Yellow -NoNewline
        $CreatingLyncAccountChoice = Read-Host
        $CreatingLyncAccountChoice = $CreatingLyncAccountChoice.ToLower()
    }
    Until ($CreatingLyncAccountChoice -eq "y" -or $CreatingLyncAccountChoice -eq "n")
    $CreatingLyncAccount.Value = $CreatingLyncAccountChoice
    If ($CreatingLyncAccountChoice -eq "y")
    {
        GetWorkPhone ([ref]$NewWorkPhone) ([ref]$NewWorkPhoneE164) ([ref]$NewWorkPhoneLast4)
        GetMobilePhone ([ref]$NewFirstName) ([ref]$NewMobilePhone)  
    }

    


    
    Write-Host "`n"
    Write-Host "Alright, here's the information you've supplied. Please look it over and make sure it's correct."
    Write-Host "------------------------"
    Write-Host "UPN: $NewUPN"
    Write-Host "User Name: $NewUserName"
    Write-Host "First Name: $NewFirstName"
    Write-Host "Middle Initial: $NewMI"
    Write-Host "Last Name: $NewLastName"
    Write-Host "Display Name: $NewDisplayName"
    Write-Host "Title: $NewJobTitle"
    Write-Host "Department: $NewDepartment"
    Write-Host "Campus: $NewOffice"
    Write-Host "Supervisor: $NewSupervisorFullname ($NewSupervisor)"
    Write-Host "Primary Email Address: $NewEmailAddress1"
    Write-Host "Secondary Email Address: $NewEmailAddress2"
    Write-Host "Work Phone: $NewWorkPhone"
    Write-Host "Work Phone (E164): $NewWorkPhoneE164"
    Write-Host "Work Phone Last 4: $NewWorkPhoneLast4"
    Write-Host "Mobile Phone: $NewMobilePhone"

}

function GetUserName( [ref]$NewFirstName, [ref]$NewLastName, [ref]$NewMI, [ref]$NewDisplayName, [ref]$NewUserName, [ref]$NewUPN )
{
    Write-Host "First name: " -ForegroundColor White -NoNewline
    $NewFirstName.Value = Read-Host
    Write-Host "Last name: " -ForegroundColor White -NoNewline
    $NewLastName.Value = Read-Host
    Write-Host "`n"
    $NewDisplayName.Value = $NewFirstName.Value + ' ' + $NewLastName.Value
    $FormedUserName = $NewFirstName.Value.Substring(0,1) + $NewLastName.Value
    $NewUserName.Value = $FormedUserName.ToLower()
    $UserNameCompare = $NewUserName.Value
    Write-Host "Checking to see if $UserNameCompare already exists..." -ForegroundColor Yellow
    $TestUserName = Get-ADUser -LDAPFilter "(sAMAccountName=$UserNameCompare)"
    Sleep -Seconds 1
    If ($TestUserName -eq $null) {
        Write-Host "User name $UserNameCompare is unique. Good to go!." -ForegroundColor Green
        $NewMI.Value = $null
        $NewUPN.Value = $NewUserName.Value + "@newpointe.org"
        Sleep -Seconds 1
        Write-Host "`n"
    }
    Else {
        Write-Host "Username $UserNameCompare already exists, so let's add the user's middle initial to the username to make it unique." -ForegroundColor Red
        Sleep -Seconds 1
        Write-Host "What is their middle initial? " -NoNewline
        $NewMI.Value = Read-Host
        $NewMI.Value = $NewMI.Value.ToUpper()
        $NewDisplayName.Value = $NewFirstName.Value + " " + $NewMI.Value + " " + $NewLastName.Value
        $NewUserName.Value = $NewFirstName.Value.Substring(0,1) + $NewMI.Value + $NewLastName.Value
        $NewUserName.Value = $NewUserName.Value.ToLower()
        $UserNameCompare = $NewUserName.Value
        Write-Host "`n"
        Write-Host "OK, let's try $UserNameCompare and see if it's taken..."
        Write-Host "`n"
        Sleep -Seconds 1
        $TestUserName = Get-ADUser -LDAPFilter "(sAMAccountName=$UserNameCompare)"
        If ($TestUserName -eq $null) {
            Write-Host "User name $UserNameCompare is unique. Good to go!" -ForegroundColor Green
            $NewUPN.Value = $NewUserName.Value + "@newpointe.org"
            Sleep -Seconds 1
            Write-Host "`n"
        }
        Else {
            $UsernameVerified = $false
            Do {
                Write-Host "Username $UserNameCompare already exists, so you'll need to enter a custom user name here." -ForegroundColor Red
                Write-Host "Enter a custom user name: " -NoNewline
                $CustomUserName = Read-Host
                $NewUserName = $CustomUserName
                Write-Host "`n"
                Write-Host "OK, let's try $NewUserName and see if it's taken..."
                Sleep -Seconds 1
                $TestUserName = Get-ADUser -LDAPFilter "(sAMAccountName=$NewUserName)"
                If ($TestUserName -eq $null) {
                    Write-Host "User name $UserNameCompare is unique. Good to go!" -ForegroundColor Green
                    $UsernameVerified = $true
                    $NewUPN.Value = $NewUserName.Value + "@newpointe.org"
                    Sleep -Seconds 1
                    Write-Host "`n"
                }
                Else {
                }
            }
            While ($UsernameVerified -eq $false)
        }
    }
}

function GetWorkPhone( [ref]$NewWorkPhone, [ref]$NewWorkPhoneE164, [ref]$NewWorkPhoneLast4 )
{
    $WorkPhoneVerified = $false
    Do {
        Write-Host "Work phone number for $NewFirstName -- Format should be XXX-XXX-XXXX (or leave blank for none): " -ForegroundColor White -NoNewline
        $InputWorkPhone = Read-Host
        If ($InputWorkPhone -ne [string]::Empty){
            $NewWorkPhoneAreaCode = $InputWorkPhone.Substring(0,3)
            $NewWorkPhoneExchange = $InputWorkPhone.Substring(4,3)
            $NewWorkPhoneExt = $InputWorkPhone.Substring(8,4)
            $NewWorkPhone.Value = "+1 (" + $NewWorkPhoneAreaCode + ") " + $NewWorkPhoneExchange + "-" + $NewWorkPhoneExt
            $WorkPhoneCompare = $NewWorkPhone.Value
            Write-Host  "Checking to see if $WorkPhoneCompare already exists..."
            $TestWorkPhone = Get-ADUser -Filter {((OfficePhone -eq $WorkPhoneCompare) -or (MobilePhone -eq $WorkPhoneCompare))}
            Sleep -Seconds 1
            If ($TestWorkPhone -eq $null) {
                $WorkPhoneVerified = $true
                Write-Host "$WorkPhoneCompare is unique. Good to go!" -ForegroundColor Green
                $NewWorkPhoneE164.Value = "tel:+1" + $NewWorkPhoneAreaCode + $NewWorkPhoneExchange + $NewWorkPhoneExt
                $NewWorkPhoneLast4.Value = $NewWorkPhoneExt
                Write-Host "E.164-Formatted phone number will be "$NewWorkPhoneE164.Value -ForegroundColor Yellow
            }
            Else {
                Write-Host "The phone number $WorkPhoneCompare is already present in AD. Please use a different number." -ForegroundColor Red
            }
        }
        Else{
            $NewWorkPhone = $null
            $WorkPhoneVerified = $true    
        }
    }
    While ($WorkPhoneVerified -eq $false)
}

function GetMobilePhone( [ref]$NewFirstName, [ref]$NewMobilePhone )
{
    $UserName = $NewFirstName.Value
    $MobilePhoneVerified = $false
    Do {
        Write-Host "Mobile phone number for $UserName -- Format should be XXX-XXX-XXXX (or leave blank for none): " -ForegroundColor White -NoNewline
        $InputMobilePhone = Read-Host
        If ($InputMobilePhone -ne [string]::Empty){
            Sleep -Seconds 1
            $NewMobilePhoneAreaCode = $InputMobilePhone.Substring(0,3)
            $NewMobilePhoneExchange = $InputMobilePhone.Substring(4,3)
            $NewMobilePhoneExt = $InputMobilePhone.Substring(8,4)
            $NewMobilePhone.Value = "+1 (" + $NewMobilePhoneAreaCode + ") " + $NewMobilePhoneExchange + "-" + $NewMobilePhoneExt
            $MobilePhoneCompare = $NewMobilePhone.Value
            Write-Host  "Checking to see if $MobilePhoneCompare already exists..."
            $TestMobilePhone = Get-ADUser -Filter {((OfficePhone -eq $MobilePhoneCompare) -or (MobilePhone -eq $MobilePhoneCompare))}
            Sleep -Seconds 1
            If ($TestMobilePhone -eq $null) {
                $MobilePhoneVerified = $true
                Write-Host "$MobilePhoneCompare is unique. Good to go!" -ForegroundColor Green
            }
            Else {
                Write-Host "The phone number $MobilePhoneCompare is already present in AD. Please use a different number." -ForegroundColor Red
            }
        }
        Else{
            $NewMobilePhone = $null
            $MobilePhoneVerified = $true
        }
    }
    While ($MobilePhoneVerified -eq $false)
}

function MakeEmailAddresses ([ref]$NewFirstName, [ref]$NewLastName, [ref]$NewMI, [ref]$NewUserName, [ref]$NewEmailAddress1, [ref]$NewEmailAddress2)
{

    $EmailDefault = $NewUserName.Value
    $EmailFirst = $NewFirstName.Value
    $EmailLast = $NewLastName.Value
    $EmailMI = $NewMI.Value
    $EmailUser = $NewUserName.Value
    Do 
    {
        Write-Host "
        --- Please select an email domain for $UserName ---
        1. newpointe.org
        2. None (no email for this user)
        "
        $choice1 = Read-Host -Prompt "Make a selection and press Enter"
    }
    Until ($choice1 -eq "1" -or $choice1 -eq "2")

    Switch ($choice1) {
        "1" 
        {
            #Generate the user's "first-initial-last-name" address.
            $EmailDefault = $EmailDefault.ToLower()
            $NewEmailAddress1.Value = $EmailDefault + "@newpointe.org"
            #Generate the user's "firstname.lastname" address. If $NewMI is NOT null, then we'll generate a firstname.mi.lastname address.
            If ($EmailMI -ne $null)
            {
                $NewEmailAddress2.Value = $EmailFirst.ToLower() + "." + $EmailMI.ToLower() + "." + $EmailLast.ToLower() + "@newpointe.org"
            }
            Else
            {
                $NewEmailAddress2.Value = $EmailFirst.ToLower() + "." + $EmailLast.ToLower() + "@newpointe.org"
            }
            Write-Host "$EmailFirst's email addresses will be as follows:"
            Write-Host "Email address 1: "$NewEmailAddress1.Value
            Write-Host "Email Address 2: "$NewEmailAddress2.Value
            Write-Host "`n"
        }
        "2"
        {
            $NewEmailAddress1.Value = $null
            $NewEmailAddress2.Value = $null
            Write-Host "OK, no email address for $UserName then.`n"
        }
    }
    Sleep -Seconds 1   
}

function GetOffice ([ref]$NewFirstName, [ref]$NewOffice)
{
    $UserName = $NewFirstName.Value
    $NewOfficeVerified = $false
    Do
    {
        Do 
        {
            Write-Host "
            --- Please select the campus that $UserName will be at: ---
            1. Central Services
            2. Akron
            3. Canton
            4. Coshocton
            5. Dover
            6. Millersburg
            7. Wooster
            "
            $choice1 = Read-Host -Prompt "Make a selection and press Enter"
        }
        Until ($choice1 -In 1..7)
        Switch ($choice1) {
            "1" {$OfficeChoice = "Central Services"}
            "2" {$OfficeChoice = "Akron Campus"}
            "3" {$OfficeChoice = "Canton Campus"}
            "4" {$OfficeChoice = "Coshocton Campus"}
            "5" {$OfficeChoice = "Dover Campus"}
            "6" {$OfficeChoice = "Millersburg Campus"}
            "7" {$OfficeChoice = "Wooster Campus"}
        }
        Write-Host "You selected "$OfficeChoice". Is this what you want? (Y or N): " -ForegroundColor Yellow -NoNewline
        $NewOfficeConfirmation = Read-Host
        $NewOfficeConfirmation = $NewOfficeConfirmation.ToLower()
        If ($NewOfficeConfirmation -eq "y")
        {
            $NewOffice.Value = $OfficeChoice
            $NewOfficeVerified = $true
            Sleep -Seconds 1
        }
    }
    Until ($NewOfficeVerified -eq $true)
}

function GetDepartment( [ref]$NewFirstName, [ref]$NewDepartment )
{
    $UserName = $NewFirstName.Value
    $NewDepartmentVerified = $false
    Do
    {
        Do 
        {
            Write-Host "
            --- Please select the department that $UserName will be in: ---
            1. Adult Ministries
            2. Business Operations
            3. Communications
            4. Creative Arts
            5. Executive Team
            6. Facilities
            7. Family Life
            8. Student Ministries
            "
            $choice1 = Read-Host -Prompt "Make a selection and press Enter"
        }
        Until ($choice1 -In 1..9)
        Switch ($choice1) {
            "1" {$DepartmentChoice = "Adult Ministries"}
            "2" {$DepartmentChoice = "Business Operations"}
            "3" {$DepartmentChoice = "Communications"}
            "4" {$DepartmentChoice = "Creative Arts"}
            "5" {$DepartmentChoice = "Executive Team"}
            "6" {$DepartmentChoice = "Facilities"}
            "7" {$DepartmentChoice = "Family Life"}
            "8" {$DepartmentChoice = "Student Ministries"}
        }
        Write-Host "You selected "$DepartmentChoice". Is this what you want? (Y or N): " -ForegroundColor Yellow -NoNewline
        $NewDepartmentConfirmation = Read-Host
        $NewDepartmentConfirmation = $NewDepartmentConfirmation.ToLower()
        If ($NewDepartmentConfirmation -eq "y")
        {
            $NewDepartment.Value = $DepartmentChoice
            $NewDepartmentVerified = $true
            Sleep -Seconds 1
        }
    }
    Until ($NewDepartmentVerified -eq $true)
}


function GetSupervisor( [ref]$NewFirstName, [ref]$NewSupervisor, [ref]$NewSupervisorFullname)
{
    $SupervisorVerified = $false
    $UserName = $NewFirstName.Value
    Do
    {
        Write-Host "Enter the username of the person that $UserName will be reporting to: " -NoNewline -ForegroundColor White
        $InputSupervisor = Read-Host
        If ($InputSupervisor -ne [string]::Empty)
        {
            Write-Host "`n"
            Sleep -Seconds 1
            $SearchResult = Get-ADUser -Filter {(sAMAccountName -eq $InputSupervisor)}
            If ($SearchResult -ne $null)
            {
                $SupervisorName = $SearchResult.Name
                Write-Host "The person you selected as $UserName's supervisor is $SupervisorName. Is this correct? (Y or N): " -NoNewline -ForegroundColor Yellow
                $SupervisorConfirmation = Read-Host
                $SupervisorConfirmation = $SupervisorConfirmation.ToLower()
                If ($SupervisorConfirmation -eq "y")
                {
                    $NewSupervisorFullname.Value = $SupervisorName
                    $NewSupervisor.Value = $SearchResult.SamAccountName
                    $SupervisorVerified = $true
                }
            }
            Else
            {
                Write-Host "No user found with this username. Please try again"
                Sleep -Seconds 1
            }
        }
        Else
        {
            Write-Host "You left the supervisor field blank. Are you sure you want to assign $UserName with no supervisor? (Y or N): " -NoNewline -ForegroundColor Yellow
            $SupervisorConfirmation = Read-Host
            Write-Host "`n"
            $SupervisorConfirmation = $SupervisorConfirmation.ToLower()
            If ($SupervisorConfirmation -eq "y")
            {
                $NewSupervisor.Value = $null
                $SupervisorVerified = $true
            }
        }
    }
    Until ($SupervisorVerified -eq $true)
}

function GetJobTitle ( [ref]$NewFirstName, [ref]$NewJobTitle )
{
    $UserName = $NewFirstName.Value
    Do
    {
        Write-Host "What is $Username's job title? " -NoNewline -ForegroundColor Yellow
        $InputJobTitle = Read-Host
    }
    Until ($InputJobTitle -ne [string]::Empty)
    $NewJobTitle.Value = $InputJobTitle
}


#This function will create our AD account using the data we've supplied via the CollectInfo function.
function CreateADAccount ([ref]$NewUserName, [ref]$NewFirstName, [ref]$NewMI, [ref]$NewLastName, [ref]$NewDisplayName, [ref]$NewJobTitle, [ref]$NewDepartment, [ref]$NewOffice, [ref]$NewSupervisor, [ref]$NewWorkPhone, [ref]$NewMobilePhone, [ref]$NewUPN)
{
    Write-Host "Creating AD Account ........................... " -NoNewline
    New-ADUser -Name $NewDisplayName.Value -AccountPassword (ConvertTo-SecureString -AsPlainText "Password100" -Force) -Department $NewDepartment.Value -DisplayName $NewDisplayName.Value -GivenName $NewFirstName.Value -UserPrincipalName $NewUPN.Value -Manager $NewSupervisor.Value -MobilePhone $NewMobilePhone.Value -Office $NewOffice.Value -OfficePhone $NewWorkPhone.Value -Company "NewPointe Community Church" -SamAccountName $NewUserName.Value -Surname $NewLastName.Value -Title $NewJobTitle.Value -Enable $true
    Write-Host "Done!" -ForegroundColor Green
    Write-Host "Waiting 30 seconds for AD to sync up .......... " -NoNewline
    Sleep 30
    Write-Host "Done!" -ForegroundColor Green
}

#This function creates an Exchange mailbox for our new user if they need one.
function CreateExchangeMailbox ([ref]$NewUPN, [ref]$NewEmailAddress1, [ref]$NewEmailAddress2)
{
    $UPN = $NewUPN.Value
    $PrimaryEmail = $NewEmailAddress1.Value
    $SecondaryEmail = $NewEmailAddress2.Value
    Write-Host "Connecting to Exchange Server ................. "
    #$SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://<ExchangeServer>/PowerShell/ -Authentication Kerberos
    Import-PSSession $ExchangeSession -AllowClobber
    Write-Host "Done!" -ForegroundColor Green
    Write-Host "Creating Mailbox for $NewUserName ............. "
    Enable-Mailbox -Identity $UPN -Database '<ExchangePrimaryDB>'
    Write-Host "Done! (Primary Email: $PrimaryEmail)" -ForegroundColor Green
    Write-Host "Adding secondary email alias ................ "
    Set-Mailbox -Identity $UPN -EmailAddresses @{add="$SecondaryEmail"}
    Write-Host "Done! (Secondary Email: $SecondaryEmail)" -ForegroundColor Green
    Write-Host "Enabling Archive .............................. " -ForegroundColor Yellow
    Enable-Mailbox -Identity $UPN -Archive -ArchiveDatabase '<ExchangeArchiveDB>'
    Write-Host "Applying Standard Retention Policy ........... "
    Set-Mailbox -Identity $UPN -RetentionPolicy '<YourRetentionPolicy>'
    Write-Host "Done!" -ForegroundColor Green
}

function CreateLyncAccount () {
    #Start a PS Session with our Lync Server
    Write-Host "Connecting to Lync Server ..................... "
    $Credential = Get-Credential "<YourLyncAdminUsername>"
    $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    $LyncSession = New-PSSession -ConnectionUri https://LyncFEServer/ocspowershell -Credential $Credential -SessionOption $SessionOption
    Import-PSSession $LyncSession -AllowClobber
    Write-Host "Done!" -ForegroundColor Green

    #Determine our RegistrarPool setting by checking to see what campus this person will work at.
    $HomedFrontEnd = "<StandardFE>"
    $SIPAddress = "sip:" + $NewUPN
    if ($NewOffice -eq "Millersburg Campus") {
        $HomedFrontEnd = "<MIL FE>"
    } 
    If ($NewOffice -eq "Canton Campus") {
        $HomedFrontEnd = "<CAN FE>"
    }

    #Enable the account for Lync.
    Write-Host "Creating Lync account ......................... " -NoNewline
    Enable-CsUser -Identity $NewUPN -RegistrarPool $HomedFrontEnd -SipAddressType SamAccountName  -SipDomain domain.com
    Write-Host "Done!" -ForegroundColor Green
    #Sleep a bit, because Active Directory
    Write-Host "Waiting 60 seconds for AD to sync up .......... " -NoNewline
    Sleep 60
    Write-Host "Done!" -ForegroundColor Green
    #Enable the account for Enterprise Voice and assign a phone number.
    Write-Host "Enabling EV and Phone Number................... " -NoNewline
    Set-CsUser -Identity $NewUPN -EnterpriseVoiceEnabled $true -LineURI $NewWorkPhoneE164
    Write-Host "Done!" -ForegroundColor Green
    if ($NewOffice -eq "Central Services") {
        Write-Host "Assigning Voice Policy for CNT Users........... " -NoNewline
        Grant-CsVoicePolicy -Identity $NewUPN -PolicyName "CNT Users"
    }
    Write-Host "Done!" -ForegroundColor Green
    Write-Host "Setting Conferencing PIN....................... " -NoNewline
    Set-CSClientPin -Identity $NewUPN -Pin $NewWorkPhoneLast4
    Write-Host "`n"
    Write-Host "$NewUPN"
    Write-Host "$NewOffice"
    Write-Host "$SIPAddress"
    Write-Host "$HomedFrontEnd"
    Write-Host "$NewWorkPhoneE164"
    Write-Host "$NewWorkPhoneLast4"
}

function EnableUM () {
    Write-Host "Enabling Unified Messaging..................... " -NoNewline
    Enable-UMMailbox -Identity $NewUPN -UMMailboxPolicy "MSLyncDialPlan Policy" -Pin $NewWorkPhoneLast4
    Write-Host "Done!" -ForegroundColor Green
}

Primary
