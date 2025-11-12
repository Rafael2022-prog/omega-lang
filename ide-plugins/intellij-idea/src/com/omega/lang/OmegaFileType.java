package com.omega.lang;

import com.intellij.openapi.fileTypes.LanguageFileType;
import com.omega.lang.icons.OmegaIcons;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

public class OmegaFileType extends LanguageFileType {
    
    public static final OmegaFileType INSTANCE = new OmegaFileType();
    
    private OmegaFileType() {
        super(OmegaLanguage.INSTANCE);
    }
    
    @NotNull
    @Override
    public String getName() {
        return "OMEGA File";
    }
    
    @NotNull
    @Override
    public String getDescription() {
        return "OMEGA blockchain programming language file";
    }
    
    @NotNull
    @Override
    public String getDefaultExtension() {
        return "mega";
    }
    
    @Nullable
    @Override
    public Icon getIcon() {
        return OmegaIcons.FILE;
    }
}