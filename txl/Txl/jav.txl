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
		P [package_comment_tagging] [class_comment_tagging]
end function

rule class_comment_tagging
	replace [class_declaration]
		CL [class_declaration]
	deconstruct CL
    	CL_head [class_header] CL_body [class_body]
	deconstruct CL_head
	    M [repeat modifier] 'class CL_name [class_name] EX [opt extends_clause] IM [opt implements_clause]
	deconstruct CL_name
		CL_name_2 [declared_name]
	deconstruct CL_name_2
	   CL_name_3 [id] GP [opt generic_parameter]   
	construct string_name [stringlit]
		"temp_class"
	construct tagged_CL [class_declaration]
		'checked CL_head CL_body
	by
		tagged_CL [tag_class_comments string_name] 
end rule

rule tag_class_comments class_name [stringlit]
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

%function package_parse 
%	replace [package_declaration]
%		Comment [repeat comment_NL] PackageHeader [opt package_header] ImportDeclarations [repeat import_declaration] TypeDeclarations [repeat type_declaration]
%	by
%		Comment PackageHeader ImportDeclarations [importComment] TypeDeclarations [classParser]
%end function
%
%function importComment 
%	replace [repeat import_declaration]
%		Import [import_declaration] rest [repeat import_declaration]
%	by
%		Import rest [importComment]
%end function
%
%function classParser
%	replace [repeat type_declaration]
%		classDec [type_declaration] rest [repeat type_declaration]
%	by
%		classDec rest
%end function

%function matchToEmpty
%	match [import_declaration]
%		Empty [space]
%end function


%rule type_comments 
%	replace [repeat type_declaration]
%		TypeDeclaration [type_declaration] MoreTypeDeclarations [repeat type_declaration]
%	by
%		TypeDeclaration MoreTypeDeclarations
%end rule
%
%rule import_comments 
%	replace [repeat import_declaration]
%		ImportDeclaration [import_declaration] MoreImportDeclarations [repeat import_declaration]
%	by
%		ImportDeclaration MoreImportDeclarations
%end rule

%function main
%    replace [program]
%	   P [program]
%    construct newP [program]
%        P [packageTagger]
%    by
%        newP
%end function

%function packageTagger
%    replace [package_declaration]
%        PA [package_declaration]
%    construct newPack [package_declaration]
%        PA [resolvePackageComment] [resolvePackage]
%    by
%        NewPack
%end function

%function resolvePackageComment
%    replace [comment_NL]
%        C [comment_NL]
%    by 
%        <package_comment name = 'package...'>C</package_comment>
%end function

%function resolvePackage
%    replace [opt package_header]
%        P [opt package_header]
%    by
%        <package name = 'package.P'>P</package>
%end function