package com.omega.lang.eclipse;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.jface.text.IDocument;
import org.eclipse.jface.text.IDocumentPartitioner;
import org.eclipse.jface.text.rules.FastPartitioner;
import org.eclipse.jface.text.rules.IPartitionTokenScanner;
import org.eclipse.ui.editors.text.FileDocumentProvider;

public class OmegaDocumentProvider extends FileDocumentProvider {

	protected IDocument createDocument(Object element) throws CoreException {
		IDocument document = super.createDocument(element);
		if (document != null) {
			IPartitionTokenScanner scanner = new OmegaPartitionScanner();
			IDocumentPartitioner partitioner = new FastPartitioner(scanner, OmegaPartitionScanner.OMEGA_PARTITION_TYPES);
			partitioner.connect(document);
			document.setDocumentPartitioner(partitioner);
		}
		return document;
	}
}