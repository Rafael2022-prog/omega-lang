package com.omega.lang;

import com.intellij.lang.Language;

public class OmegaLanguage extends Language {
    
    public static final OmegaLanguage INSTANCE = new OmegaLanguage();
    
    private OmegaLanguage() {
        super("OMEGA");
    }
}