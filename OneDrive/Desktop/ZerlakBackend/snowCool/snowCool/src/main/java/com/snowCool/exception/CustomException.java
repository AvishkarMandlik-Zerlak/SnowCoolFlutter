package com.snowCool.exception;

import org.springframework.http.HttpStatus;

public class CustomException extends RuntimeException {
	
	private HttpStatus status;
   
	public CustomException(String message , HttpStatus status) {
        super(message);
        this.status = status;
    }
    
    public CustomException(String message , Throwable cause, HttpStatus status)
    {
    	super(message,cause);
    	this.status = status;
    }
}
