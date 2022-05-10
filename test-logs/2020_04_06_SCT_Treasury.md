# SCT Treasury manual tests logs

## Wallets used in tests

### sct governor
0x8B3A08b22d25C60e4b2BfD984e331568ECa4C299

### sct treasury reserve manager
0x94cd0f84feC287f2426E90f0D6653Ba8FA29BD8E

### marketplace carbon project owner
0xAB3d4f780BfCaF17bC5B4A19cbBa95357655B036

### sct treasury carbon project buyer
0x513906d9b238955B7e4A499Ad98E0B90F9503EB4

## Smart Contracts used in tests

### SCT Solid Dao Management (authority)

Address: 0x54005ab145e74d6354fe81390523e67dc40da64f
Source: https://mumbai.polygonscan.com/address/0x54005ab145e74d6354fe81390523e67dc40da64f#code

### SCTERC20 Token

Address: 0x19b20cEacef5993697F8a5F0be1C071E406329dE
Source: https://mumbai.polygonscan.com/address/0x19b20cEacef5993697F8a5F0be1C071E406329dE#code

### SCT Carbon Treasury

Address: 0x9E16dAa388447E103A12cA61E4D19254B6d21d5e
Source: https://mumbai.polygonscan.com/address/0x9E16dAa388447E103A12cA61E4D19254B6d21d5e#code

### marketplace ERC1155 reserve token
Address: 0x4D3470e7567d805b29D220cc462825d1abee7D87
Source: https://mumbai.polygonscan.com/address/0x4D3470e7567d805b29D220cc462825d1abee7D87#code

## Txs executed in tests

Deploy SCT Treasury an set timelock to 10
https://mumbai.polygonscan.com/tx/0x48efe347ea69b647d96d2b4428f4711c68f4cf4db8a5b3631f8b538f0fb2c32d

Initialize SCT Treasury
https://mumbai.polygonscan.com/tx/0x95bc2e4b197eb49a7010cea9f951ae4b00bb1277b64f52c03a50deb1ae3af4b7

Order timelock to add marketplace ERC1155 as reserve token
https://mumbai.polygonscan.com/tx/0x73dbecf612f1b1c7c775606936c9b8fa9d7cabf861b9d8f26b96716410512854

Execute timelock order to add marketplace ERC1155 as reserve token
https://mumbai.polygonscan.com/tx/0x84077df09d95b7a77f31b04f8399064c5b4132a8515449d09633d741d8173fbc

Disable timelock(twice)
https://mumbai.polygonscan.com/tx/0xbb00b8c67b3e6d98ca550ac17d04393d66603c61812cb8420e21543860189033
https://mumbai.polygonscan.com/tx/0x3143ebf04464f855ece330606cd11b136c4f458620546cd50cc94260199efc4f

Disable marketplace ERC1155 as reserve token
https://mumbai.polygonscan.com/tx/0xab5852bda78146ccb1f646e6108756ae524b627a4f158ab6b7f69199015302a2

Enable marketplace ERC1155 as reserve token
https://mumbai.polygonscan.com/tx/0x3c7cf523a9244a74e9484e1e143fd30cdfe3496efc59e1bf2e054bb87cfd53cb

Enable reserve manager wallet
https://mumbai.polygonscan.com/tx/0x3c3e84d35f24a8cb1834f09e1f6501f2395210371d702b316fb63044f828d9ac

Manager Create marketplace carbon project token id 31
["0x4D3470e7567d805b29D220cc462825d1abee7D87",31,100,1,1,1,1,true,false,false]
https://mumbai.polygonscan.com/tx/0x304a1b2eadbec6c56b0b014ad5c2c70b07aa946d0f4c566dc81b07344e781abd

Manager Create marketplace carbon project token id 32
["0x4D3470e7567d805b29D220cc462825d1abee7D87",32,100,2,2,2,2,true,false,false]
https://mumbai.polygonscan.com/tx/0xfd6dff77c93914fede122a699da267b7b06d877d4fca0e7106d69d58bb144766

Manager Create marketplace carbon project token id 33
["0x4D3470e7567d805b29D220cc462825d1abee7D87",33,100,2,1,2,1,true,false,false]
https://mumbai.polygonscan.com/tx/0x732e8916c1a74d200875f36b18778865d6b9f5268086e88c0065021dcb440f9e

Manager Create certified marketplace carbon project token id 34
["0x4D3470e7567d805b29D220cc462825d1abee7D87",34,100,1,2,1,2,false,true,false]
https://mumbai.polygonscan.com/tx/0x7cd265315d0049ef1e6867238b63d269de80ad6be8dd5063a9cf459c0285c3fb

Manager Create inactive marketplace carbon project token id 35
["0x4D3470e7567d805b29D220cc462825d1abee7D87",35,100,1,1,1,2,false,true,true]
https://mumbai.polygonscan.com/tx/0x36db120372d7b7c5c043fd64f7efa4d31a3de88a65f4819ae51019b323888003

Owner approve sct treasury spend owner marketplace carbon project tokens
https://mumbai.polygonscan.com/tx/0x1af69340df09b1c1ce7f579816d46f4899bc038f4136069317ab766e9fa56571

Owner Deposit marketplace reserve token id 31
https://mumbai.polygonscan.com/tx/0x11c1a7273604a64d677f71eb54e3c7be2e257449d60c950c9ac16edc07959f5f

Owner Deposit marketplace reserve token id 32
https://mumbai.polygonscan.com/tx/0x27b39d4e60e171081a8fa727951f5bdfcd0e6d43e83a7cd3f837350f3ef85262

Owner Deposit marketplace reserve token id 33
https://mumbai.polygonscan.com/tx/0xb49fd091786d0ec7c858bcd08e9f01dfa3a3c04385c635100ccd540dfb6558d9

Buyer Allow SCT Treasury spend 300 SCT tokens
https://mumbai.polygonscan.com/tx/0xb308d5933d5883b820833e7ea1cd51410b6bb6ceb9c2401299b2b0ad889d2842

Buyer Create Offer to buy token id 31
["0x4D3470e7567d805b29D220cc462825d1abee7D87",31,"0x513906d9b238955B7e4A499Ad98E0B90F9503EB4",10,20,0]
https://mumbai.polygonscan.com/tx/0xc918bbbc0240ffe92222668f6116844fc5ee44ba6a4655d340e45b1bbc992396

Buyer Cancel offer id 1 to buy token id 31
https://mumbai.polygonscan.com/tx/0x9b9a86cec481b2d8162e328a457542e3b40997a4b75fc8b1a182a5f4d18323df

Buyer Create Offer to buy token id 32
["0x4D3470e7567d805b29D220cc462825d1abee7D87",32,"0x513906d9b238955B7e4A499Ad98E0B90F9503EB4",100,200,0]
https://mumbai.polygonscan.com/tx/0x8510b6fc1322fae466f070927332ca731ab15d0c254d43ca6b29691a76e5274d

Owner Approve offer id 2 to sell token id 32
https://mumbai.polygonscan.com/tx/0x30b11833167727da693c6c557c7b4c66c5e841edcb663ad90fd8e783c5b616e2

Enable timelock
https://mumbai.polygonscan.com/tx/0xf971991948499703d9eab5426035ac1d76d82a7f11b2884a55256e42d8a71013

