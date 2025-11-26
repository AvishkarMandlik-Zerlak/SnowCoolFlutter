package com.snowCool.util;

import com.snowCool.model.User;

public final class AccessControlUtil {
    private AccessControlUtil() {}

    public static boolean isAdmin(User user) {
        return user != null && user.getRole() != null && user.getRole().trim().equalsIgnoreCase("ADMIN");
    }

    public static boolean hasPermission(User user, Boolean permissionFlag) {
        if (isAdmin(user)) return true; // Admin shortcut
        return permissionFlag != null && permissionFlag; // employee flag must be true
    }
}

