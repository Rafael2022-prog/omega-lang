package com.omega.lang.eclipse;

import org.eclipse.jface.text.rules.IWordDetector;
import org.eclipse.jface.text.rules.IRule;
import org.eclipse.jface.text.rules.WordPatternRule;

public class OmegaWordRule extends WordPatternRule {

	public OmegaWordRule(org.eclipse.jface.text.rules.IToken token) {
		super(new IWordDetector() {
			public boolean isWordStart(char c) {
				return !Character.isWhitespace(c) && c != '"' && c != '/';
			}

			public boolean isWordPart(char c) {
				return !Character.isWhitespace(c) && c != '"' && c != '/';
			}
		}, "", "", token);
	}
}