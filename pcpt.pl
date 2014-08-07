#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

use lib 'Tree-Nary-1.3/lib';
use Tree::Nary;

$LN2 = log 2;

# This script builds a path-compressed prefix trie from a text file
# and saves it to XML format.

if(!$ARGV[0]){
	die "Must specify input file\n";
}

open TEXT_FILE, $ARGV[0];
@text_file = <TEXT_FILE>; #Read in entire text file
close TEXT_FILE;

$text_file = join '', @text_file;

if(length $text_file == 0){
	exit; #We're done
}

printXMLcomment("Building XML file...");

$data = {};
$$data{STRING} = "";
$$data{HITS} = 0;
$$data{PARENT} = undef;

$root = Tree::Nary->new($data);

build_pcpt($text_file);

print "<pcpt>\n";
print_trie($root);
print "</pcpt>\n";

sub print_trie{

	my $i;

	if(${$_[0]->{'data'}}{HITS}){
		for($i = 1; $i < $_[0]->depth($_[0]); $i++){
			print "  ";
		}
		$num_children = $_[0]->n_children($_[0]);
		print "<L _ = \"(${$_[0]->{'data'}}{HITS}, $num_children";

		if(!$_[0]->is_leaf($_[0])){
			$node_entropy = calc_entropy($_[0]);
			print ", $node_entropy) ";
		}
		else{
			print ") ";
		}

		if(${$_[0]->{'data'}}{STRING}){
			print ${$_[0]->{'data'}}{STRING};
		}
		if($_[0]->is_leaf($_[0])){
			print "\"/>\n";
		}
		else{
			print "\">\n";
		}
	}

	for($i = 0; $i < $_[0]->n_children($_[0]); $i++){
		print_trie($_[0]->nth_child($_[0], $i));
	}

	if(!$_[0]->is_leaf($_[0])){
		for($i = 1; $i < $_[0]->depth($_[0]); $i++){
			print "  ";
		}
		print "</L>\n";
	}

}

sub build_pcpt{

	while(length $text_file != 0){	

		insert_string($text_file);
		$text_file = pre_chop($text_file);

	}

}

sub calc_entropy{

	my $i;
	my $entropy = 0;
	my @probs = ();

	$parent_hits = ${$_[0]->{'data'}}{HITS};

	for($i = 0; $i < $_[0]->n_children($_[0]); $i++){
		$child = $_[0]->nth_child($_[0], $i);
		$nth_prob = ((${$child->{'data'}}{HITS}) / $parent_hits);
		push @probs, $nth_prob;
	}

	foreach $prob (@probs) {
		$entropy += (-1 * ($prob * ((log $prob) / $LN2)));

	}

	return $entropy;

}

sub printXMLcomment{

	print "<!-- $_[0] -->\n";

}

sub pre_chop{

	return substr $_[0], 1, length $_[0];

}

#This sub returns the longest common prefix
sub longest_common_prefix {
    my $prefix = shift;
    for (@_) {
	chop $prefix while (! /^\Q$prefix/);
    }
    return $prefix;
}


sub insert_string{

	$current_node = $root;
	$insert_string = $_[0];
	$partial_match = 1;

	#current_node = root
	#foreach child of current node:
	#  compare child_string with insert_string
	#  if child_string is completely matched and portion of insert_string remains:
	#    descend (current = child, return to top of loop)
	#  else if child_string is partially matched
	#    if insert_string is fully matched
	#      create new node
	#      return
	#    else
	#      create new nodeS
	#      return
	#  else if child_string is completely unmatched
	#    next iteration of loop
	#
	#if no matches were found and portion of insert_string remains
	# create new node

	while($partial_match){
		$partial_match = 0;

		for($i = 0; $i < $current_node->n_children($current_node); $i++){
			$child = $current_node->nth_child($current_node, $i);
			
			$child_string = ${$child->{'data'}}{STRING};#${$child->{'data'}}{STRING}
			$prefix = longest_common_prefix($insert_string, $child_string);
			$prefix_length = length $prefix;
			$insert_string_length = length $insert_string;

			if($prefix_length == 0){ #completely unmatched, go to next iteration of loop
				next;
			}
			else{ #partial or complete match
				if($prefix_length == length $child_string){ #complete node string match
					if($prefix_length < $insert_string_length){ #partial insert string match
						$partial_match = 1;
						$insert_string =~ /^\Q$prefix/;
						$insert_string = $';
						$current_node = $child; #descend
						last;
					}
					else{ #complete insert string match
						update_hits($child);
						return; #nothing to do here... we're done
					}
				}
				elsif($prefix_length < length $child_string){ #partial node string match
					if($prefix_length < $insert_string_length){ #partial insert string match

						#This section is a little complicated:
						# Tree before:
						#
						# Node A "a" <--- $current_node
						# +-Node B "bra" <--- $child
						#   +-Node C "cadabrabarabbas"
						#   +-Node D "barabbas"
						#
						# Insert "abarabbas" @ Node A
						# 
						# Node B must be split in half - "bra" vs. "barabbas"
						#
						#Section 1:
						# Node A "a"
						# +-Node B "bra"
						# | +-Node C "cadabrabarabbas"
						# | +-Node D "barabbas"
						# +-Node E "b" <--- add this
						#
						#Section 2a:
						# Node A "a"
						# +-Node B "ra" <--- cull the pre-match
						# | +-Node C "cadabrabarabbas"
						# | +-Node D "barabbas"
						# +-Node E "b" <--- add this
						#
						#Section 2b:
						# Node A "a"
						# +-Node E "b"
						#						
						# Node B "ra" <--- unlink this
						# +-Node C "cadabrabarabbas"
						# +-Node D "barabbas"
						#
						#Section 2b:
						# Node A "a"
						# +-Node E "b"
						#   +-Node B "ra" <--- add it back in as E's child
						#     +-Node C "cadabrabarabbas"
						#     +-Node D "barabbas"
						#
						#Section 3:
						# Node A "a"
						# +-Node E "b"
						#   +-Node B "ra"
						#   | +-Node C "cadabrabarabbas"
						#   | +-Node D "barabbas"
						#   +-Node F "arabbas" <-- finally, add this
						#
						
						#Section 1:
						$hash_ref = {};
						$$hash_ref{STRING} = $prefix;
						$$hash_ref{HITS} = ${$child->{'data'}}{HITS};
						$new_node = $current_node->insert_data;
						$$hash_ref{PARENT} = $current_node;
						$insert_node = $current_node->insert_data($current_node, -1, $hash_ref);

						#Section 2:
						${$child->{'data'}}{STRING} =~ $prefix;
						${$child->{'data'}}{STRING} = $'; #keep the suffix
						$child->unlink($child); #unlinked_node is independent tree now
						${$child->{'data'}}{PARENT} = $insert_node;
						$insert_node->insert($insert_node, -1, $child);

						#Section 3:
						$insert_string =~ /^\Q$prefix/;
						$hash_ref = {};
						$$hash_ref{STRING} = $';
						$$hash_ref{HITS} = 0;
						$$hash_ref{PARENT} = $insert_node;
						$new_node = $child->insert_data($insert_node, -1, $hash_ref);
						update_hits($new_node);
						return;

					}
					else{ #complete insert string match
						#truncate current_node string past prefix
						${$child->{'data'}}{STRING} = $prefix;

						#create child node with current_node string suffix
						$child_string =~ /^\Q$prefix/;
						$hash_ref = {};
						$$hash_ref{STRING} = $';
						$$hash_ref{HITS} = 0;
						$$hash_ref{PARENT} = $child;
						$new_node = $child->insert_data($child, -1, $hash_ref);
						update_hits($new_node);
						return;

					}

				}
		
			}

		}

	}

	#no match was found among a node's children, adding as a sibling
	$hash_ref = {};
	$$hash_ref{STRING} = $insert_string;
	$$hash_ref{HITS} = 0;
	$$hash_ref{PARENT} = $current_node;
	$new_node = $current_node->insert_data($current_node, -1, $hash_ref);
	update_hits($new_node);

}

sub update_hits{

	$current_node = $_[0];

	while(defined $current_node){

		${$current_node->{'data'}}{HITS}++;
		$current_node = ${$current_node->{'data'}}{PARENT};

	}

}
