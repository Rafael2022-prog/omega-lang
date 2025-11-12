package com.omega.lang.eclipse;

import org.eclipse.jface.text.rules.IWhitespaceDetector;

public class OmegaWhitespaceDetector implements IWhitespaceDetector {

	public boolean isWhitespace(char character) {
		return Character.isWhitespace(character);
	}
}