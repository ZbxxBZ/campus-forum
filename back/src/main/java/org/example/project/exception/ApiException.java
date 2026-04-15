package org.example.project.exception;

import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {
    private final HttpStatus httpStatus;
    private final int code;
    private final Object data;

    public ApiException(String message) {
        this(HttpStatus.BAD_REQUEST, 1, message, null);
    }

    public ApiException(int code, String message) {
        this(HttpStatus.BAD_REQUEST, code, message, null);
    }

    public ApiException(HttpStatus httpStatus, int code, String message, Object data) {
        super(message);
        this.httpStatus = httpStatus;
        this.code = code;
        this.data = data;
    }

    public HttpStatus getHttpStatus() {
        return httpStatus;
    }

    public int getCode() {
        return code;
    }

    public Object getData() {
        return data;
    }
}
