#!/usr/bin/perl -w

# Author: Clayton Bauman
# License: BSD

#Builds a prefix trie on word boundaries (go back to root on whitespace)

use Graph;
use Class::Struct;

struct VertexData => {
	CHAR => '$',
	DEPTH => '$',
	PARENT => '$',
	NUMBER => '$',
};

if($#ARGV < 0){
	$name = "mygraph";
}
else{
	$name = shift @ARGV;
}

@input = <>; #Read STDIN

$input = join '', @input;
@input = split /\s+/, $input;

if($#input < 0){
	exit; #We're done
}

$graph = new Graph;

$root = new VertexData;
$root->CHAR("");
$root->PARENT(undef);
$root->DEPTH(0);

$graph->add_vertex($root);

build_prefix_trie_on_graph(@input);

print_graph_to_dot($graph);

#$writer->write_graph($graph, "$name.dot");
#system("dot $name.dot -Tps -o $name.ps");
#system("gv $name.ps &");


#4. Constructing the DAWG
#	We now turn to the problem of constructing the DAWG for S. The algorithm we
#have developed builds the DAWG in a simple on-line fashion, reading each word
#from S and updating the current DAWG to reflect the addition of the new word.
#Individual words are also processed on-line in one left-to-right scan.
#	The algorithm is a simple extension of the algorithm given in [8] to build the
#DAWG for a single word. Additional steps required are indicated by starred lines.
#The heart of the algorithm is given in the function update, and its auxiliary
#function, split. Given a DAWG for the set S = ( w_l, . . . , w_i) (annotated with certain
#additional information described below), a pointer to the node represented by Wi
#(called activenode) and a letter a, update modifies the annotated DAWG to create
#the annotated DAWG for S’ = (w_1, , . . . , w_i-1, w_ia). When processing on a new
#word begins, activenode is set to the source. Split is called by update when an
#equivalence class from =RS' must be partitioned into two classes in =RS'.
#	Two types of annotation are required. First, each of the transition edges of the
#DAWG is labeled either as a primary or as a secondary edge. The edge labeled a
#from the class represented by x to the class represented by y is primary if xa = y.
#Otherwise, it is secondary. The primary edges form a directed spanning tree of the
#DAWG defined by taking only the longest path from the source to each node. The
#second kind of annotation is the addition of a sufix pointer to each node. The
#suffix pointer of a node in the DAWG points to the parent of the corresponding
#node in the tree T(S). Equivalently, there is a suffix from the node represented by
#x to the node represented by y whenever y is the largest suffix of x that is not
#equivalent to x under =RS (Lemma 5). The source is the only node that does not
#have a suffix pointer. Suffix pointers are analogous to those used by McCreight
#[17] and correspond to pointers used by Pratt, who gives an algorithm related to
#ours in [20].
#	The algorithm to build the DAWG is given in the Appendix. In consists of the
#main procedure builddawg and auxiliary functions update and split.
#	The key to the linear time bound for this construction algorithm is that using
#suffix pointers and primary or secondary marked edges, all of the structures that
#must be modified by update can be located rapidly. Here it is important that suffix
#pointers allow us to work from the longest suffixes backward to successively shorter
#suffixes, stopping when no more work needs to be done. Simpler methods that
#involve keeping track of all “active suffixes” will be potentially O(n^2) (e.g., [151]).
#In addition, it is important that the states do not need to be marked with structural
#information about the equivalence classes they represent. This is in contrast to the
#O(n^2) methods of [22], that build similar structures by directly partitioning the
#equivalence classes in an iterative manner.
#
#
#The following is a detailed algorithm to build the DAWG for a set of texts S.
#
#builddawg(S)
#	1. Create a node named source.
#	2. Let activenode be source.
#	3. For each word w of S do:*
#		A. For each letter a of w do:
#			Let activenode be update (activenode, a).
#		B. Let activenode be source.
#	4. Return source.
#
#update (activenode, a)
#	1. If activenode has an outgoing edge labeled a, then*
#		A. Let newactivenode be the node that this edge leads to.*
#		B. If this edge is primary, return newactivenode.*
#		C. Else, return split (activenode, newactivenode).*
#	2. Else
#		A. Create a node named newactivenode.
#		B. Create a primary edge labeled a from activenode to newactivenode.
#		C. Let currentnode be activenode.
#		D. Let suffixnode be undefined.
#		E. While currentnode isn’t source and suffixnode is undefined do:
#			i. Let currentnode be the node pointed to by the suffix pointer of currentnode.
#			ii. If currentnode has a primary outgoing edge labeled a, then let suffixnode be the
#			node that this edge leads to.
#			iii. Else, if currentnode has a secondary outgoing edge labeled a then
#				a. Let childnode be the node that this edge leads to.
#				b. Let suffixnode be split (currentnode, childnode).
#			iv. Else, create a secondary edge from currentnode to newactivenode labeled a.
#		F. If suffixnode is still undefined, let suffixnode be source.
#		G. Set the suffix pointer of newactivenode to point to suffixnode.
#		H. Return newactivenode.
#
#split (parentnode, childnode)
#	1. Create a node called newchildnode.
#	2. Make the secondary edge from parentnode to childnode into a primary edge from
#	parentnode to newchildnode (with the same label).
#	3. For every primary and secondary outgoing edge of childnode, create a secondary outgoing
#	edge of newchildnode with the same label and leading to the same node.
#	4. Set the suffix pointer of newchildnode equal to that of childnode.
#	5. Reset the suffix pointer of childnode to point to newchildnode.
#	6. Let currentnode be parentnode.
#	7. While currentnode isn’t source do:
#		A. Let currentnode be the node pointed to by the suffrx pointer of currentnode.
#		B. If currentnode has a secondary edge to childnode, then make it a secondary edge to
#		newchildnode (with the same label).
#		C. Else, break out of the while loop.
#	8. Return newchildnode.




sub build_prefix_trie_on_graph{

	foreach (@_) {
		insert_string($graph, $root, $_);
	}

}

sub insert_string{

	$graph = shift;
	$current_node = shift;

	if(!defined $_[0]){
		return;
	}
	
	$insert_string = shift;

	if((length($insert_string) == 0) or $insert_string eq ""){ #terminal condition
		return;
	}

	$leading_char_of_insert_string = substr $insert_string, 0, 1;

#	@out_edges = $graph->edges_from($current_node);

#	foreach $edge (@out_edges) {
#		$to_vertex = $$edge[1];
#		if($to_vertex->CHAR() eq $leading_char_of_insert_string){
		$peer_vertex = find_peer($leading_char_of_insert_string,$current_node);
		if($peer_vertex){
#			print "Found a peer!\n";
			if(length $insert_string > 1){
				$insert_string = substr $insert_string, 1; #chop off the leading character
				$graph->add_edge($current_node, $peer_vertex); #adds the edge and the vertex
				insert_string($graph, $peer_vertex, $insert_string);
			}
			return;
		}
#	}

	#create new child, then recurse
	$new_node = new VertexData;
	$new_node->CHAR($leading_char_of_insert_string);
	$new_node->DEPTH($current_node->DEPTH() + 1);
	$new_node->PARENT($current_node);
	$graph->add_edge($current_node, $new_node); #adds the edge and the vertex
	if(length $insert_string > 1){
		$insert_string = substr $insert_string, 1; #chop off the leading letter
		insert_string($graph, $new_node, $insert_string);
	}

}

sub print_graph_to_dot{

	my $i;
	my $graph = $_[0];

	print "digraph $name\{\n";

	print_nodes($graph);
	print_edges($graph);

	print "}\n";

}

sub print_nodes{

	my $graph = $_[0];
	$num_nodes = 0;

	@nodes = $graph->vertices;

	print "    /* List of nodes */\n";
	foreach $node (@nodes) {
		$char = $node->CHAR();
		print "    node$num_nodes\[label = \"$char\"\];\n";
		$node->NUMBER($num_nodes);
		$num_nodes++;
	}
	print"\n";

}

sub print_edges{

	my $graph = $_[0];

	@edges = $graph->edges;

	print "    /* List of edges */\n";
	foreach (@edges) {
		$begin_vertex_num = $$_[0]->NUMBER();
		$end_vertex_num = $$_[1]->NUMBER();
		print "    node$begin_vertex_num -> node$end_vertex_num;\n";
	}
	print"\n";

}

sub find_peer{

	$char = shift;
	$curr_node = shift;
	@nodes = $graph->vertices;
	@peer_nodes = ();

	foreach $node (@nodes) {
#		$node_char = $node->CHAR();
#		print "Comparing $node_char and $char\n";
		if($node->CHAR() eq $char){
#			print "equal!\n";
#			$curr_node_char = $curr_node->CHAR();
#			print "Looking for ancestry between $curr_node_char and $node_char\n";
			if(!is_ancestor($curr_node,$node)){
#				print "No ancestors!\n";
				push @peer_nodes, $node;
			}
#			else{
#				print "Oops, found ancestral relationship\n";
#			}
		}
	}

	if($#peer_nodes < 0){
		return 0;
	}
	else{
		return shallowest(@peer_nodes);
	}

}

sub shallowest{
	$min = $_[0];
	foreach (@_) {
		if($_->DEPTH() < $min->DEPTH()){
			$min = $_;
		}
	}
	return $min;
}

#returns true if $_[0] is an ancestor of $_[1], false otherwise
sub is_ancestor{
	$ancestor_candidate = shift;
	$match_node = shift;
	while(defined $match_node->PARENT()){
		if($ancestor_candidate == $match_node){
			return 1;
		}
		$match_node = $match_node->PARENT();
	}
	return 0;
}
