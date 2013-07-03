% Parser for Java programs
% Jim Cordy, January 2008

% Using Java 5 grammar
include "java.grm"

% Uncomment to parse and preserve comments
#define COMMENTS

#ifdef COMMENTS
    include "javaCommentOverrides.grm"
#endif

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
	construct tag_string [stringlit]
		"class"
	construct TaggedClassC [comment_block_NL]
		'<COMMENT 'type = tag_string 'value = ClassName '> FirstComment OtherComments
		'</COMMENT>
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
    	CB [class_body_tagging class_name]
end function

function class_body_tagging class_name [id]
	replace [repeat class_body_declaration]
		Body [repeat class_body_declaration]
	deconstruct Body
		firstPart [class_body_declaration] rest [repeat class_body_declaration]
	by
		firstPart rest [member_comment_tagger class_name] [class_body_tagging class_name]
		% [instance_tagger] [static_tagger] [field_tagger] 
end function

function member_comment_parser class_name [id]
	replace [class_body_declaration]
		CD [class_body_declaration]
	deconstruct CD
		member [member_declaration]
	by
		member [class_comment_tagger] [method_comment_parser class_name]
end function

function method_comment_parser class_name [id]
	replace [method_declaration]
		MD [method_declaration]
	deconstruct MD
		MC [method_or_constructor_declaration]
	by
		MC [method_comment_tagger class_name] %[constructor_comment_tagger class_name]
end function

function method_comment_tagger class_name [id]
	replace [method_declarator]
	
end function

rule tag_class_comments class_name [id]
	replace [comment_block_NL]
		CB [comment_block_NL]
	deconstruct CB
		FirstComment [comment_NL] OtherComments [repeat comment_NL] 
	construct tag_string [stringlit]
		"class"
	construct Tag_Comments [comment_block_NL]
		'<COMMENT 'type = tag_string 'value = class_name '> FirstComment OtherComments
		'</COMMENT>
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
		'<COMMENT 'type = tag_string '> FirstComment OtherComments
		'</COMMENT>		
	by
		Tag_Comments PackageHeader ImportDeclarations TypeDeclarations
end rule