package com.omega.lang.eclipse;

import org.eclipse.jface.text.TextAttribute;
import org.eclipse.jface.text.rules.IRule;
import org.eclipse.jface.text.rules.IToken;
import org.eclipse.jface.text.rules.RuleBasedScanner;
import org.eclipse.jface.text.rules.SingleLineRule;
import org.eclipse.jface.text.rules.Token;
import org.eclipse.jface.text.rules.WhitespaceRule;
import org.eclipse.jface.text.rules.WordRule;

public class OmegaCodeScanner extends RuleBasedScanner {

	private static String[] keywords = {
		"blockchain", "state", "constructor", "function", "public", "private", 
		"view", "pure", "payable", "returns", "emit", "event", "mapping",
		"address", "uint256", "string", "bool", "require", "if", "else",
		"for", "while", "return", "true", "false"
	};

	public OmegaCodeScanner() {
		IToken keywordToken = new Token(new TextAttribute(null, null, 1)); // Bold
		IToken stringToken = new Token(new TextAttribute(null, null, 2)); // Italic
		IToken commentToken = new Token(new TextAttribute(null, null, 0)); // Normal
		IToken otherToken = new Token(new TextAttribute(null, null, 0));

		setRules(new IRule[] {
			// Add rule for strings
			new SingleLineRule("\"", "\"", stringToken, '\\'),
			// Add rule for single line comments
			new SingleLineRule("//", null, commentToken),
			// Add generic whitespace rule.
			new WhitespaceRule(new OmegaWhitespaceDetector()),
			// Add word rule for keywords
			createWordRule(keywords, keywordToken),
			// Default rule
			new OmegaWordRule(otherToken)
		});
		
		setDefaultReturnToken(otherToken);
	}

	private WordRule createWordRule(String[] words, IToken token) {
		WordRule rule = new WordRule(new OmegaWordDetector(), token);
		for (String word : words) {
			rule.addWord(word, token);
		}
		return rule;
	}
}