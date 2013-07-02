% Parser for Java programs
% Jim Cordy, January 2008

% Using Java 5 grammar
include "java.grm"

% Uncomment to parse and preserve comments
#define COMMENTS

#ifdef COMMENTS
    include "javaCommentOverrides.grm"
#endif

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