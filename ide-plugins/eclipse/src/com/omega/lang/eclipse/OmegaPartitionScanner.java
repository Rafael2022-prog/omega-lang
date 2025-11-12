package com.omega.lang.eclipse;

import org.eclipse.jface.text.rules.*;

public class OmegaPartitionScanner extends RuleBasedPartitionScanner {
	
	public final static String OMEGA_COMMENT = "__omega_comment";
	public final static String OMEGA_STRING = "__omega_string";
	public final static String OMEGA_KEYWORD = "__omega_keyword";
	
	public final static String[] OMEGA_PARTITION_TYPES = new String[] {
		OMEGA_COMMENT,
		OMEGA_STRING,
		OMEGA_KEYWORD
	};

	public OmegaPartitionScanner() {
		super();
		
		IToken commentToken = new Token(OMEGA_COMMENT);
		IToken stringToken = new Token(OMEGA_STRING);
		
		IPredicateRule[] rules = new IPredicateRule[2];
		
		// Rule for single-line comments
		rules[0] = new SingleLineRule("//", "", commentToken);
		
		// Rule for strings
		rules[1] = new SingleLineRule("\"", "\"", stringToken, '\\');
		
		setPredicateRules(rules);
	}
}