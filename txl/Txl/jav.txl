% Parser for Java programs
% Jim Cordy, January 2008

% Using Java 5 grammar
include "java.grm"

% Uncomment to parse and preserve comments
#define COMMENTS

include "javaCommentOverrides.grm"


redefine class_declaration
    [attr 'checked] [class_header] [class_body]
end redefine

function main 
	replace [program]
		P [program]
	by
		P [package_comment_tagging] [class_comment_tagger]
end function


% TODO handle enum and interface
% TODO extend to also handle inner classes (allow for a parameter to be passed (optional though))
rule class_comment_tagger
	replace [type_declaration]
		TD [type_declaration]
	deconstruct TD 
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
	%construct tag_value [tag_value_rep]
	%	\"ClassName \"
	construct tag_string [stringlit]
		"class"
	construct TaggedClassC [comment_block_NL]
		<COMMENT 'type = tag_string 'value = "tag_value" > FirstComment OtherComments
		</COMMENT>
	by
		TaggedClassC CH CB [class_body_parser ClassName] 
end rule

function class_body_parser class_name [id]
	replace [class_body]
		CB [class_body]
    deconstruct CB
    	classBody [class_or_interface_body]
    deconstruct classBody
	    '{ Body [repeat class_body_declaration] '}                      
    by
    	'{ Body [class_body_tagging class_name] '}
end function

function class_body_tagging class_name [id]
	replace [repeat class_body_declaration]
		Body [repeat class_body_declaration]
	deconstruct Body
		firstPart [class_body_declaration] rest [repeat class_body_declaration]
	by
		firstPart [class_comment_tagger] [method_comment_tagger class_name] rest [class_body_tagging class_name]
		% [instance_tagger] [static_tagger] [field_tagger] 
end function

%function method_comment_parser class_name [id]
%	replace [method_declaration]
%		MD [method_declaration]
	%deconstruct MD
	%	MC [method_or_constructor_declaration]
	%by
%		MD [method_comment_tagger class_name] %[constructor_comment_tagger class_name]
%end function

function method_comment_tagger class_name [id]
	replace [class_body_declaration]
		classBody [class_body_declaration]
	deconstruct classBody
		memDec [member_declaration]
	deconstruct memDec
		metOrCon [method_or_constructor_declaration]
	deconstruct metOrCon
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
	construct TagSeparator [stringlit]
		"."
	construct TagClass [stringlit]
		_ [+ class_name]
	construct Cpath [stringlit]
		TagClass [+ TagSeparator]
	construct CMpath [stringlit]
		Cpath [+ name]
	construct tag_string [stringlit]
		"method"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = CMpath > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments modifier genPar TS Mdec THROW MB
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
		extention_path
end function

rule tag_class_comments class_name [id]
	replace [comment_block_NL]
		CB [comment_block_NL]
	deconstruct CB
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	%construct tag_value [tag_value_rep]
	%	\" class_name \"
	construct tag_string [stringlit]
		"class"
	construct Tag_Comments [comment_block_NL]
		<COMMENT 'type = tag_string 'value = "tag_value" > FirstComment OtherComments
		</COMMENT>
	by
		Tag_Comments		
end rule

rule package_comment_tagging 
	replace [package_declaration]
		 PD [package_declaration]
	deconstruct PD
		cr [comment_block_NL] PackageHeader [opt package_header] ImportDeclarations [repeat import_declaration] TypeDeclarations [repeat type_declaration]
	deconstruct cr
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	construct tag_string [stringlit]
		"package"
	construct Tag_Comments [comment_block_NL]
		'< 'COMMENT 'type = tag_string '> FirstComment OtherComments
		'</ 'COMMENT '>
		by
		Tag_Comments PackageHeader ImportDeclarations TypeDeclarations
end rule
