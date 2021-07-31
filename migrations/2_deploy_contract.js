//var P2PLending = artifacts.require("P2PLending");

//module.exports = function(deployer) {
//  deployer.deploy(P2PLending);
//};

var BT = artifacts.require("P2PTest");

module.exports = function(deployer) {
  deployer.deploy(BT);
};