/**
* @description This class is used to specialise the ComplianceException class
*   for the PolicyDistribution aspect of Compliance product.
**/
public with sharing class PolicyDistributionException extends ComplianceException {
	
    /**
    * @description This method returns the name of the product area where this exception originated.
    * @return [String] returns the product area, overriding the default value.
    **/
    public override String getProductArea(){
        return 'Policy Distribution';
    }
}