az deployment sub create --location canadacentral --template-file main.bicep --parameters environment=dev

az deployment sub create --location canadacentral --template-file main.bicep --parameters environment=dev --parameters adminUsername=testnewuser --parameters adminPassword="Test@123Password"

-------------------------------------------------------------------------
Resource Level: 
First Create Resource Group
C:\Users\tejas\Downloads\finance-infrastructure\modules> az deployment sub create --name resource-group-deployment --location canadacentral  --template-file resourceGroup.bicep --parameters environment=dev


az deployment group create --name finance-resources-deployment --resource-group rg-finance-dev --template-file main.bicep --parameters Parameters/dev.json