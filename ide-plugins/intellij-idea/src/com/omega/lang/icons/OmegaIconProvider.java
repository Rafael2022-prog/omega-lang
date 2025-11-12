package com.omega.lang.icons;

import com.intellij.ide.IconProvider;
import com.intellij.psi.PsiElement;
import com.omega.lang.OmegaFileType;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;

public class OmegaIconProvider extends IconProvider {
    
    @Override
    public @Nullable Icon getIcon(@NotNull PsiElement element, int flags) {
        if (element.getContainingFile() != null && 
            element.getContainingFile().getFileType() instanceof OmegaFileType) {
            return OmegaIcons.FILE;
        }
        return null;
    }
}