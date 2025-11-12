package com.omega.lang.eclipse;

import org.eclipse.jface.text.rules.IWordDetector;

public class OmegaWordDetector implements IWordDetector {

	public boolean isWordStart(char c) {
		return Character.isJavaIdentifierStart(c);
	}

	public boolean isWordPart(char c) {
		return Character.isJavaIdentifierPart(c);
	}
}