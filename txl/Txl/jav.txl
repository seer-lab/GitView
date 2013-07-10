% Parser for Java programs
% Jim Cordy, January 2008

% Using Java 5 grammar
include "java.grm"

% Uncomment to parse and preserve comments
#define COMMENTS

include "javaCommentOverrides.grm"

%define block_start_tag
%	'<BLOCK>
%end define

%define block_end_tag
%	'</BLOCK>
%end define

%redefine class_or_interface_body
%	[opt block_start_tag] ...
%end redefine

%redefine class_or_interface_body
%	... [opt block_end_tag]
%end redefine

%might remove..
redefine statement
    ... [opt comment_block] 
end redefine

function main 
	replace [program]
		P [program]
	by
		P [package_comment_parser] 
end function

function package_comment_parser
	replace * [package_declaration]
		 PD [package_declaration]
	construct newPD [package_declaration]
		PD [package_comment_tagger]
	deconstruct newPD
		com [opt comment_block_NL] PH [opt package_header] ID [repeat import_declaration] TD [repeat type_declaration]
	by
		com PH ID [import_comment_tagger] TD [class_comment_parser] [interface_comment_parser]
end function

rule package_comment_tagger
	replace [package_declaration]
		PD [package_declaration]
	deconstruct PD
		cr [comment_block_NL] PackageHeader [opt package_header] ImportDeclarations [repeat import_declaration] TypeDeclarations [repeat type_declaration]
	deconstruct cr
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	construct tag_string [stringlit]
		"package"
	deconstruct PackageHeader
		Anno [repeat annotation] 'package PN [package_name] ';
	deconstruct PN
		QN [qualified_name]
	deconstruct QN
		ref [reference]
	deconstruct ref
		firstPack [id] restPack [repeat component]
	construct Path [stringlit]
		_ [getPackageName firstPack restPack]
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = Path > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments PackageHeader ImportDeclarations TypeDeclarations
end rule

function getPackageName first [id] rest [repeat component]
	replace [stringlit]
		_ [stringlit]
	construct startName [stringlit]
		_ [+ first]
	by
		startName [parsePackage rest]
end function

function parsePackage rest [repeat component]
	replace [stringlit]
		start [stringlit]
	deconstruct rest
		firstId [dot_id] moreId [repeat component]
	deconstruct firstId
		'. GP [opt generic_argument] name [id]
	construct seperator [stringlit]
		"."
	construct partPath [stringlit]
 		start [+ seperator]
 	construct fullPath [stringlit]
 		partPath [+ name]
	by
		fullPath [parsePackage moreId]
end function

rule import_comment_tagger
	replace [repeat import_declaration]
		Imports [repeat import_declaration]
	deconstruct Imports
		first_import [import_declaration] otherImports [repeat import_declaration]
	deconstruct first_import
		Comment [comment_block_NL] 'import S [opt 'static] ImportName [imported_name] ';
	deconstruct Comment
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct ImportName
		Pack [package_or_type_name] Dot [opt dot_star]
	deconstruct Pack
		QN [qualified_name]
	deconstruct QN
		ref [reference]
	deconstruct ref
		firstPack [id] restPack [repeat component]
	construct Path [stringlit]
		_ [getPackageName firstPack restPack]
	construct tag_string [stringlit]
		"import"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = Path > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments 'import S ImportName '; otherImports
end rule

function import_end_comment
	replace [comment_block_NL]
		CB [comment_block_NL]
	by
		CB
end function

function interface_comment_parser
	replace [repeat type_declaration]
		TD [repeat type_declaration]
	construct newTD [repeat type_declaration]
		TD [interface_comment_tagger]
	deconstruct newTD 
		Comments [opt comment_block_NL] ID [interface_declaration] OtherTD [repeat type_declaration]
	deconstruct ID
		IH [interface_header] IB [interface_body]
	deconstruct IB
		classORInterBody [class_or_interface_body]
	by
		Comments IH classORInterBody [class_body_parser] OtherTD [class_comment_parser]
end function

rule interface_comment_tagger
	replace [repeat type_declaration]
		TD [repeat type_declaration]
	deconstruct TD
		firstTD [type_declaration] otherTD [repeat type_declaration]
	deconstruct firstTD 
		Comments [comment_block_NL] ID [interface_declaration]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	deconstruct ID
		IH [interface_header] IB [interface_body]
	deconstruct IH
		M [repeat modifier] AM [opt annot_marker] 'interface N [interface_name] EC [opt extends_clause] IC [opt implements_clause]
	deconstruct N
		DB [declared_name]
	deconstruct DB
	    ClassName [id] GP [opt generic_parameter]
	construct new_path [stringlit]
		_ [+ ClassName]
	construct tag_string [stringlit]
		"interface"
	construct TaggedClass [comment_block_NL]
		<COMMENT 'type = tag_string 'value = new_path > FirstComment OtherComments
		</COMMENT>
	by
		TaggedClass IH IB otherTD
end rule

% TODO handle enum and interface
function class_comment_parser
	replace [repeat type_declaration]
		TD [repeat type_declaration]
	construct newTD [repeat type_declaration]
		TD [class_comment_tagger]
	deconstruct newTD 
		Comments [opt comment_block_NL] CD [class_declaration] OtherTD [repeat type_declaration]
	deconstruct CD
		CH [class_header] CB [class_body]
	deconstruct CB
		classORInterBody [class_or_interface_body]
	by
		Comments CH classORInterBody [class_body_parser] OtherTD [class_comment_parser]
end function

rule class_comment_tagger
	replace [repeat type_declaration]
		TD [repeat type_declaration]
	deconstruct TD
		firstTD [type_declaration] otherTD [repeat type_declaration]
	deconstruct firstTD 
		Comments [comment_block_NL] CD [class_declaration]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	deconstruct CD
		CH [class_header] CB [class_body]
	deconstruct CH
		M [repeat modifier] 'class N [class_name] EX_clause[opt extends_clause] Imp_clause[opt implements_clause]
	deconstruct N
		DB [declared_name]
	deconstruct DB
	    ClassName [id] GP [opt generic_parameter]
	construct new_path [stringlit]
		_ [+ ClassName]
	construct tag_string [stringlit]
		"class"
	construct TaggedClass [comment_block_NL]
		<COMMENT 'type = tag_string 'value = new_path > FirstComment OtherComments
		</COMMENT>
	by
		TaggedClass CH CB otherTD
end rule

function class_body_parser
	replace [class_or_interface_body]
    	classBody [class_or_interface_body]
    deconstruct classBody
	    '{ Body [repeat class_body_declaration] '}                      
    by
    	'{ Body [class_body_tagging] '}
end function

function class_body_tagging
	replace [repeat class_body_declaration]
		Body [repeat class_body_declaration]
	deconstruct Body
		firstPart [class_body_declaration] rest [repeat class_body_declaration]
	by
		firstPart [innerClass_parser] [instance_parser] [method_comment_parser] [constructor_comment_parser] rest [class_body_tagging]
		%[field_tagger] 
end function

function instance_parser
	replace [class_body_declaration]
		CBD [class_body_declaration]
	construct newII [class_body_declaration]
		CBD [instance_tagger] [static_tagger] [block_instance_tagger] [block_static_tagger] [declaration_field_parser]
	by
		newII
end function

function innerClass_parser
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD
		MM [member_declaration]
	deconstruct MM
		TD [type_declaration]
	construct newTD [repeat type_declaration]
		TD
	construct TaggedTD [repeat type_declaration]
		newTD [class_comment_parser]
	deconstruct TaggedTD
		firstTD [type_declaration] other [repeat type_declaration]
	construct newCBD [class_body_declaration]
		firstTD
	by
		newCBD
end function

%No UUID
rule instance_tagger
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD 
		II [instance_initializer]
	deconstruct II
		Comments [comment_block_NL] Block [block]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	construct newPath [stringlit]
		_ [+ "instance_init"]
	construct tag_string [stringlit]
		"instance_initializer"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Block
end rule

%No UUID
rule static_tagger
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD 
		SI [static_initializer]
	deconstruct SI
		Comments [comment_block_NL] 'static Block [block]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	construct newPath [stringlit]
		_ [+ "static_init"]
	construct tag_string [stringlit]
		"static_initializer"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments 'static Block
end rule

%Should conider making instance_initializer and static_initializer have a single parent
function block_instance_tagger
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD
		II [instance_initializer]
	deconstruct II
		Comments [opt comment_block_NL] Block [block]
	deconstruct Block
		'{ body [repeat declaration_or_statement] '}
	construct newBlock [block]
		'{ body '}
	construct newMethodBody [method_body]
		newBlock
	construct taggedMBody [method_body]
		newMethodBody [method_body_block_tagger]
	deconstruct taggedMBody
		taggedBlock [block]
	by
		Comments taggedBlock
end function

function block_static_tagger
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD
		SI [static_initializer]
	deconstruct SI
		Comments [opt comment_block_NL] 'static Block [block]
	deconstruct Block
		'{ body [repeat declaration_or_statement] '}
	construct newBlock [block]
		'{ body '}
	construct newMethodBody [method_body]
		newBlock
	construct taggedMBody [method_body]
		newMethodBody [method_body_block_tagger]
	deconstruct taggedMBody
		taggedBlock [block]
	by
		Comments taggedBlock
end function

rule declaration_field_parser
	replace [class_body_declaration]
		CBD [class_body_declaration]
	deconstruct CBD 
		FD [field_declaration]
	deconstruct FD
		VD [variable_declaration]
	deconstruct VD
		Comments [comment_block_NL] M [repeat modifier] TS [type_specifier] varDec [variable_declarators] ';
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct * [variable_name] varDec
		name [declared_name] dem [repeat dimension]
	deconstruct name
		id [id] GP [opt generic_parameter] 
	construct newPath [stringlit]
		_ [+ id]
	construct tag_string [stringlit]
		"var_declaration"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments M TS varDec ';
end rule

function constructor_comment_parser
	replace [class_body_declaration]
		classBody [class_body_declaration]
	deconstruct classBody
		memDec [member_declaration]
	deconstruct memDec
		metOrCon [method_or_constructor_declaration]
	deconstruct metOrCon
		contDec [constructor_declaration]
	construct constr [constructor_declaration]
		contDec [constructor_comment_tagger]
	deconstruct constr
		Comment [opt comment_block_NL] modifier [repeat modifier] genPar [opt generic_parameter] CD [constructor_declarator] T [opt throws] CB [constructor_body]
	deconstruct CB
		Block [block]
	by 
		Comment modifier genPar CD T Block [method_body_block_tagger] 
end function

rule constructor_comment_tagger
	replace [constructor_declaration]
		constDec [constructor_declaration]
	deconstruct constDec
		Comment [comment_block_NL] modifier [repeat modifier] genPar [opt generic_parameter] CD [constructor_declarator] T [opt throws] CB [constructor_body]
	deconstruct CD
		ClassName [class_name] '( param [list formal_parameter] ')
	deconstruct ClassName
		decName [declared_name]
	deconstruct decName
		name [id] GP [opt generic_parameter]
	deconstruct Comment
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	construct newPath [stringlit]
		_ [+ name]
	construct tag_string [stringlit]
		"constructor"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments modifier genPar CD T CB 
end rule

function method_comment_parser
	replace [class_body_declaration]
		classBody [class_body_declaration]
	deconstruct classBody
		memDec [member_declaration]
	deconstruct memDec
		metOrCon [method_or_constructor_declaration]
	deconstruct metOrCon
		methodDec [method_declaration]
	construct Method [method_declaration]
		methodDec [method_comment_tagger]
	deconstruct Method
		Comment [opt comment_block_NL] modifier [repeat modifier] genPar [opt generic_parameter] TS [type_specifier] Mdec [method_declarator] THROW [opt throws] MB [method_body]
	deconstruct MB
		Block [block]
	by 
		Comment modifier genPar TS Mdec THROW Block [method_body_block_tagger] 
end function

rule method_comment_tagger
	replace [method_declaration]
		methodDec [method_declaration]
	deconstruct methodDec
		Comment [comment_block_NL] modifier [repeat modifier] genPar [opt generic_parameter] TS [type_specifier] Mdec [method_declarator] THROW [opt throws] MB [method_body]
	deconstruct Mdec
		methodName [method_name] '( PARAM [list formal_parameter] ') DIM [repeat dimension] PostCom [opt comment_block_NL]
	deconstruct methodName
		decName [declared_name]
	deconstruct decName
		name [id] GP [opt generic_parameter]
	deconstruct Comment
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	construct newPath [stringlit]
		_ [+ name]
	construct tag_string [stringlit]
		"method"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments modifier genPar TS Mdec THROW MB 
end rule

function method_body_block_tagger
	replace [block]
		BL [block]
	%deconstruct MB
	%	BL [block]
	deconstruct BL
		Comment [opt comment_block_NL] '{ DecORStat [repeat declaration_or_statement] '}
	construct newDec [repeat declaration_or_statement]
		DecORStat [dec_or_statement]
	by
		Comment '{ newDec '}
end function

function dec_or_statement
	replace [repeat declaration_or_statement]
		decOrStat [repeat declaration_or_statement]
	deconstruct decOrStat
		firstStat [declaration_or_statement] OtherStats [repeat declaration_or_statement]
	construct TaggedFirst [declaration_or_statement]
		firstStat [decComParser] [statement_parser]
	by
		TaggedFirst OtherStats [dec_or_statement]
end function

function decComParser
	replace [declaration_or_statement]
		dec_stat [declaration_or_statement]
	deconstruct dec_stat
		ComDec [declaration] 
	construct newComDec [declaration]
		ComDec [findClass] [findVarName]
	by
		newComDec 
end function

function findVarName
	replace [declaration]
		comDec [declaration]
	deconstruct comDec
		Comments [comment_block_NL] Dec [com_declaration]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct * [variable_name] Dec
		name [declared_name] dem [repeat dimension]
	deconstruct name
		id [id] GP [opt generic_parameter] 
	construct newPath [stringlit]
		_ [+ id]
	construct tag_string [stringlit]
		"declaration"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Dec
end function

function findClass
	replace [declaration]
		ComDec [declaration]
	deconstruct ComDec
		Comments [comment_block_NL] Dec [com_declaration]
	deconstruct Dec
		ClassDec [class_declaration]
	construct Type [type_declaration]
		Comments ClassDec
	construct TagType [type_declaration]
		Type [class_comment_parser]
	deconstruct TagType
		TagComment [comment_block_NL] class_dec [class_declaration]
	by 
		TagComment Dec
end function

function createPath path [id]
	replace [stringlit]
		_ [stringlit]
	construct NewPath [stringlit]
		_ [+ path]
	by
		NewPath
end function

function buildPath new_path [id]
	replace [stringlit]
		start_path [stringlit]
	construct extention_path [stringlit]
		start_path [+ "."]
	construct full_path [stringlit]
		extention_path [+ new_path]
	by
		full_path
end function

function statement_parser
	replace [declaration_or_statement]
		dec_stat [declaration_or_statement]
	deconstruct dec_stat
		com_statement [statement]
	construct newStatement [statement]
		com_statement [expression_tagger] [if_stat_parser] [switch_parser] [while_parser] [do_while_parser] [for_parser] [for_in_parser] [break_parser] 
	construct newStatement2 [statement]
		newStatement [continue_parser] [label_parser] [return_parser] [throw_parser] [synchronized_parser] [assert_parser] [try_parser] [return_post_parser]
	by
		newStatement2
end function

rule expression_tagger
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		express [expression_statement]
	construct tag_string [stringlit]
		"expression_statement"
	construct newPath [stringlit]
		"expression"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule if_stat_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		if [if_statement]
	construct tag_string [stringlit]
		"if_statement"
	construct newPath [stringlit]
		"if"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule switch_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		SS [switch_statement]
	construct tag_string [stringlit]
		"switch_statement"
	construct newPath [stringlit]
		"switch"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule while_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		WS [while_statement]
	construct tag_string [stringlit]
		"while_statement"
	construct newPath [stringlit]
		"while"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule do_while_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		DS [do_statement]
	construct tag_string [stringlit]
		"do_while_statement"
	construct newPath [stringlit]
		"do"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule for_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		FS [for_statement]
	construct tag_string [stringlit]
		"for_statement"
	construct newPath [stringlit]
		"for"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule for_in_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		FS [for_in_statement]
	construct tag_string [stringlit]
		"for_in_statement"
	construct newPath [stringlit]
		"for_in"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule break_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		BS [break_statement]
	construct tag_string [stringlit]
		"break_statement"
	construct newPath [stringlit]
		"break"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule continue_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		ContS [continue_statement]
	construct tag_string [stringlit]
		"continue_statement"
	construct newPath [stringlit]
		"continue"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule label_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		LS [label_statement]
	construct tag_string [stringlit]
		"label_statement"
	construct newPath [stringlit]
		"label"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule return_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement] otherComment [opt comment_block]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		RS [return_statement]
	construct tag_string [stringlit]
		"return_statement"
	construct newPath [stringlit]
		"return"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement otherComment
end rule

rule return_post_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [opt comment_block_NL] Statement [com_statement] otherComments [comment_block]
	deconstruct otherComments
		FirstComment [comment_NL]
	%	FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		RS [return_statement]
	construct tag_string [stringlit]
		"return_statement_after"
	construct newPath [stringlit]
		"return"
	construct Tag_Comments [comment_block]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment </COMMENT>
	by
		Comments Statement Tag_Comments
end rule

rule throw_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		TS [throw_statement]
	construct tag_string [stringlit]
		"throw_statement"
	construct newPath [stringlit]
		"throw"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule synchronized_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		SS [synchronized_statement]
	construct tag_string [stringlit]
		"synchronized_statement"
	construct newPath [stringlit]
		"synchronized"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule assert_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		AS [assert_statement]
	construct tag_string [stringlit]
		"assert_statement"
	construct newPath [stringlit]
		"assert"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule

rule try_parser
	replace [statement]
		CS [statement]
	deconstruct CS
		Comments [comment_block_NL] Statement [com_statement]
	deconstruct Comments
		FirstComment [comment_NL] OtherComments [repeat comment_NL]
	deconstruct Statement
		AS [try_statement]
	construct tag_string [stringlit]
		"try_statement"
	construct newPath [stringlit]
		"try"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = newPath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments Statement
end rule