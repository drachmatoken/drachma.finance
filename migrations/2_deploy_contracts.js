var DrachmaToken = artifacts.require("DrachmaToken.sol");
var ObolToken = artifacts.require("ObolToken.sol");

module.exports = async function(deployer) {
    await deployer.deploy(DrachmaToken, { gas: 7000000 })
    await deployer.deploy(ObolToken, { gas: 7000000 })
}