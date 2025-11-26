package com.snowCool.service;

import com.snowCool.model.User;
import com.snowCool.exception.CustomException;
import org.springframework.stereotype.Service;
import java.util.*;
import com.snowCool.dto.LoginRequestDTO;
import com.snowCool.dto.LoginResponseDTO;


public interface UserService {

    User login(String username, String password);

    User saveUser(User user);

    LoginResponseDTO login(LoginRequestDTO loginRequestDTO);
    
    boolean deleteById(Long id);
    
    User findById(Long id);
}
