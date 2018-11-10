
#Create a resource group
New-AzureRmResourceGroup -Name TestM3 -Location EastUs

#Create a subnet configuration 
$subnetConfig= New-AzureRmVirtualNetworkSubnetConfig `
              -Name M3VNetSN -AddressPrefix 192.168.10.0/25 
           
#Create a virtual network 
$vnet= New-AzureRmVirtualNetwork -ResourceGroupName TestM3 -Location EastUS  `
      -Name M3VNet -Addressprefix 192.168.0.0/16 -Subnet $subnetConfig 

#Create a public IP address and specify a DNS name 
$pip= New-AzureRmPublicIpAddress -ResourceGroupName TestM3 -Location EastUS `
-AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "M3PublicDNS$(Get-Random)" 

#Create an inbound network security group rule for port 3389 
$nsgRuleRDP= New-AzureRmNetworkSecurityRuleConfig -Name RDP -Protocol TCP `
-Direction Inbound -Priority 1000 -sourceAddressPrefix * -sourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 3389 -Access Allow 

#Create an inbound network security group rule for port 80 
$nsgRuleWeb= New-AzureRmNetworkSecurityRuleConfig -Name WEB -Protocol TCP -Direction Inbound -Priority 1001 `
-SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
-DestinationportRange 80 -Access Allow 

#Create a network security group 
$nsg= New-AzureRmNetworkSecurityGroup -ResourceGroupName TestM3 -Location EastUS `
-Name M3NSG -SecurityRules $nsgRuleRDP,$nsgRuleWeb 


#Create a virtual network card and associate with public IP address and NSG 
$nic=New-AzureRmNetworkInterface -Name M3VM01NIC -ResourceGroupName TestM3 -Location EastUS `
-SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id 


#Define a credential object 
$secpasswd = ConvertTo-SecureString "1q2w3e4r5t6y*" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ("cem", $secpasswd)


#Create a virtual machine configuration 
$vmConfig=New-AzureRmVMConfig -VMName M3VM01 -VMSize Standard_DS1_v2 |  `
Set-AzureRmVMOperatingSystem -Windows -ComputerName M3VM01 -Credential $creds | ` 
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
-Skus 2016-Datacenter -version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id

 #Create the VM
  New-AzureRmVM -ResourceGroupName TestM3 -Location EastUS -VM $vmConfig

