/**
* @description This class is used to specialise the ComplianceException class
*   for the Policy Content Document aspect of Compliance product.
**/
public with sharing class PolicyContentDocumentException extends ComplianceException {
	
    /**
    * @description This method returns the name of the product area where this exception originated.
    * @return [String] returns the product area, overriding the default value.
    **/
    public override String getProductArea(){
        return 'Policy Content Document';
    }
}