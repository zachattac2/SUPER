# SUPER
Next we will create a new policy by going to Jamf Pro > Computers > Policies > New. I currently have this configured:

General
Display Name: Software Updates – S.U.P.E.R.M.A.N.
Enabled = True
Category: Software Updates
Trigger: Recurring Check-in & Custom
Execution Frequency: Once per computer
Scripts
Add the super script to your scripts payload
Priority: After
Parameter Values:
Parameter 4: --jamf-account=superapi

Parameter 5: --jamf-password=secureP@ssword

Parameter 6: --reset-super