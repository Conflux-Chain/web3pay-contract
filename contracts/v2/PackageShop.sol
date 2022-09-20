// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./PackageInterface.sol";

//import "hardhat/console.sol";

contract PackageShop {
    PackageInterface template;
    PackageInterface instance;
    function setContracts(address template_, address instance_) public {
        template = PackageInterface(template_);
        instance = PackageInterface(instance_);
    }
    function buy(uint templateId) public {
        //console.log("templateId: %s , template c %s", templateId, address(template));
        PackageInterface.Template memory t = template.getTemplate(templateId);
        require(t.id>0);
        PackageInterface.Package memory p = PackageInterface.Package(
            0,//id
            templateId,
            t.name,
            t.description,
            t.icon,
            t.duration
        );
        instance.makePackage(msg.sender, p);
    }
}
