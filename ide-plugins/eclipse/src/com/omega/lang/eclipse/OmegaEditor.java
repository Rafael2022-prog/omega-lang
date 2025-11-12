package com.omega.lang.eclipse;

import org.eclipse.ui.editors.text.TextEditor;
import org.eclipse.ui.editors.text.TextFileDocumentProvider;
import org.eclipse.ui.IEditorInput;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.jface.text.IDocument;
import org.eclipse.jface.text.source.ISourceViewer;
import org.eclipse.jface.text.source.SourceViewerConfiguration;

public class OmegaEditor extends TextEditor {
    
    public static final String ID = "com.omega.lang.eclipse.OmegaEditor";
    
    public OmegaEditor() {
        super();
        setDocumentProvider(new OmegaDocumentProvider());
        setSourceViewerConfiguration(new OmegaSourceViewerConfiguration());
    }
    
    @Override
    protected void initializeEditor() {
        super.initializeEditor();
        setEditorContextMenuId("#OmegaEditorContext");
    }
    
    @Override
    public void doSave(IProgressMonitor monitor) {
        super.doSave(monitor);
    }
    
    @Override
    public void doSaveAs() {
        super.doSaveAs();
    }
    
    @Override
    public boolean isSaveAsAllowed() {
        return true;
    }
}