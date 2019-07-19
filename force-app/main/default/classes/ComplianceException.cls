/**
* @description This class is used to specialise the Exception class for the Product
*              Compliance.
**/
public virtual with sharing class ComplianceException extends Exception{

    public ApexPages.Severity severity {get;set;}

    /**
    * @description This method returns the name of the product where this exception originated.
    * @return [String] returns the product name.
    **/
    public String getProductName(){
        return 'Compliance';
    }

    /**
    * @description This virtual method returns the area of the product where this exception originated.
    * @return [String] returns the product area, the default value is 'Unknown'.
    **/
    public virtual String getProductArea(){
        return 'Unknown';
    }

    /**
    * @description This virtual method returns the exception in a string format.
    * @return [String] returns the exception as a string.
    **/
    public virtual String getExceptionString(){
        return '\n\tProduct:  ' + this.getProductName() +
               '\n\tArea:  ' + this.getProductArea() +
               '\n\tType:  ' + (this.getTypeName() != null ? this.getTypeName() : 'Unknown') +
               '\n\tCause:  ' + (this.getCause() != null ? String.valueOf(this.getCause()) : 'Unknown') +
               '\n\tMessage:  ' + (this.getMessage() != null ? this.getMessage() : 'Unknown') +
               '\n\tStack Trace:  ' + (this.getStackTraceString() != null ? this.getStackTraceString() : 'Unknown');
    }

    /**
    * @description This method returns a page message constructed from the exception.
    * @return [ApexPages.Message] returns the exception as an ApexPages.Message.
    **/
    public ApexPages.Message getPageMessage(){
        return new ApexPages.Message((this.severity != null ? this.severity : ApexPages.Severity.INFO ), this.getMessage());
    }

    /**
    * @description This method adds a page message constructed from the exception to the ApexPages message list.
    **/
    public void addPageMessage(){
        ApexPages.addMessage(this.getPageMessage());
    }
}