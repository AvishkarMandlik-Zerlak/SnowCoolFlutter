package com.snowCool.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@Component
public class GlobalExceptionHandler 
{
	@ExceptionHandler
	public ResponseEntity<SnowCoolErrorResponse> handle(CustomException exec)
	{
		SnowCoolErrorResponse err = new SnowCoolErrorResponse();

		err.setStatus(HttpStatus.NOT_FOUND.value());
		err.setTimeStamp(System.currentTimeMillis());
		err.setMessage(exec.getMessage());
		
		return new ResponseEntity<SnowCoolErrorResponse>(err,HttpStatus.NOT_FOUND);
	}
}
