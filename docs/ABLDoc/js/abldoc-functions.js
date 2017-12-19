
$(document)
		.ready(
				function() {
					//mark each node with child and parent classes 
					$('.tree li').each(
									function() {
										if ($(this).children('ul').length > 0) {
											$(this).addClass('parent');
										} else {
											$(this).addClass('child');
											
										}
										$(this).addClass('show');
										var padding = 16 * $(this).parents(".tree li").length;
										$(this).children("a").first().css("margin-left", padding);
									});
					/*node click listeners*/
					$('.tree li.child > a').click(function() {
						$(this).selectNode();
						$(this).updateSlimScroll();
					});
					$('.tree li.parent > a').click(function() {
						$(this).parent().toggleClass('active');
						$(this).parent().children('ul').slideToggle('fast');
						$(this).selectNode();
						$(this).updateSlimScroll();
					});
					/*Selects the node, updates the bg color and opens the link in the frame*/
					$.fn.extend({
						selectNode : function() {
							curSelection.children("div").first().css("background-color", "");
							curSelection.children("a").first().css('color','#54565B');
							curSelection = $(this).parent();
							$(this).prev().css("background-color", "#0d6987");
							$(this).css("color", "white");
							$("#myFrame").attr("src", $(this).attr("href"));
						}

					});
					/*toggle all, not used for now*/
					$('#all').click(function() {

						$('.tree li').each(function() {
							$(this).toggleClass('active');
							$(this).children('ul').slideToggle('fast');

						});
					});

					/* click event for menu icon, toggles the tree view. */
					$(' #toggleLeft ').click(function() {
						$(' #treeDiv ').toggle();
						if ($(' #treeDiv ').is(":visible")) {
							$('#main').css("left", "275px");
						} else {
							$('#main').css("left", "5px");
						}
					});

					/*Selects the previous file*/
					$(' #goLeft ').click(
									function() {
										var prevSibling = curSelection.prev("li.show");
										if (prevSibling.length != 0) {
											if (prevSibling.hasClass("parent")) {
												// special case
												var curNode = prevSibling.goToPrevNode();
												curNode.parents("li").each(
																function() {
																	$(this).children("a")
																			.first()
																			.navigateToNode();
																});
												curNode.children("a").first()
														.navigateToNode();
												curNode.children("a").first()
														.selectNode();
											} else if (prevSibling.hasClass("child")) {
												var curNode = prevSibling;
												curNode.children("a").first()
														.navigateToNode();
												curNode.children("a").first()
														.selectNode();
											}
										} else {
											// reached end of the child nodes,
											// go to parent folder node
											var parent = curSelection.closest(
													"ul").closest("li.show");
											if (parent.length == 0) {
												// reached start, go to the end
												var lastParent = $(".tree li.parent.show").last();
												var curNode = lastParent
														.goToPrevNode();
												curNode.parents("li").each(
																function() {
																	$(this).children("a")
																			.first()
																			.navigateToNode();
																});
												curNode.children("a").first()
														.navigateToNode();
												curNode.children("a").first()
														.selectNode();
											} else {
												var curNode = parent;
												curNode.children("a").first()
														.navigateToNode();
												curNode.children("a").first()
														.selectNode();
											}
										}
									});

					/*Selects the next file in the tree view*/
					$(' #goRight ').click(
									function() {
										if (curSelection.hasClass("parent")) {
											if (!curSelection
													.hasClass("active")) {
												curSelection
														.toggleClass('active');
												curSelection.children('ul')
														.slideDown('fast');
											}
											var child = curSelection.find("li.show")
													.first();
											if (child.length == 0) {
												// a folder must have children
												// this is an unlikely case
											} else {

												child.children("a").first()
														.navigateToNode();
												child.children("a").first()
														.selectNode();
											}
										} else if (curSelection
												.hasClass("child")) {
											var childSibling = curSelection
													.next("li.show");
											if (childSibling.length == 0) {
												var parSibling = curSelection
														.goToNextParent();
												if (typeof parSibling == "undefined"
														|| parSibling.length == 0) {
													// reached end, go to start
													var startNode = $(
															".tree li.show").first();
													startNode.children("a")
															.first()
															.navigateToNode();
													startNode.children("a")
															.first()
															.selectNode();
												} else {

													parSibling.children("a")
															.first()
															.navigateToNode();
													parSibling.children("a")
															.first()
															.selectNode();
												}
											} else {

												childSibling.children("a")
														.first()
														.navigateToNode();
												childSibling.children("a")
														.first().selectNode();
											}
										}

									});
					/*Recursively finds the next node,
					used when previous file link in the toolbar is clicked*/
					$.fn.extend({
						goToNextParent : function() {
							var parent = $(this).closest("ul").closest("li.show");
							if (parent.length == 0) {
								// hit the end
								return parentSibling;
							}
							// get parents sibling
							var parentSibling = parent.next("li.show");
							if (parentSibling.length != 0) {
								return parentSibling;
							}
							return parent.goToNextParent();
						}

					});
					
					/*Recursively finds the previous parent, 
					used when previous file link in the toolbar is clicked*/
					$.fn.extend({
						goToPrevNode : function() {
							var lastChild = $(this).children("ul").first()
									.children("li.show").last();
							if (lastChild.hasClass("parent")) {
								// recursively go thru the folders till child
								// node is found
								return lastChild.goToPrevNode();
							} else {

								return lastChild;
							}
						}

					});
					/*Reveals the node*/
					$.fn.extend({
						navigateToNode : function() {
							$(this).parent().toggleClass('active');
							$(this).parent().children('ul').slideDown('fast');
						}

					});
					
					/*Handles on hover color change of bg and text*/
					$(".tree a").hover(function() {
						if (!$(this).parent().is(curSelection)) {
							$(this).prev().css({
								"background-color" : "#F0F0F3" 
							});
							//$(this).prev().addClass("hover-bg");
							$(this).css({
								"color" : "#57c0a4"
							});
						}

					}, function() {
						if (!$(this).parent().is(curSelection)) {
							$(this).css({
								"color" : "#54565B"
							});
							$(this).prev().css({
								"background-color" : ""
							});
						}

					});
					
					//reveal the first node of the tree view.
					$.fn.extend({
						revealFirstNode : function() {
							curSelection = $('.tree li.parent').first();
							if (curSelection.length != 0) {
								curSelection.children("a").first().navigateToNode();
							}		
						}

					});
					
					$.fn.extend({
						collapseAllNodes : function() {
							$(".tree li.parent").each(function() {
								 $(this).removeClass('active');
								 $(this).children('ul').slideUp('fast');
							});		
						}

					});
					/* handles search */
					$("#searchBox").keyup(function(){
						
						if($(this).val() == ''){
							$(".tree li").each(function() {
								$(this).addClass('show');
								$(this).show();
							});
							$(this).collapseAllNodes();
							$(this).revealFirstNode();
						}else{

							var searchVal = "^".concat($(this).val());
							//replace all *(wildcards) with [a-zA-Z]*
							searchVal = searchVal.replace(/\*/g, "(.)*");
							//replace all ? with [a-zA-Z]?
							searchVal = searchVal.replace(/\?/g,"(.)?");
							//escape period from search string
							//searchVal = searchVal.replace(/\./g,"\.");
							var searchRegExp = new RegExp(searchVal,'i');
							$(".tree li.child").each(function(){
								var nodeText = $(this).children("a").first().text();
								var valid = searchRegExp.test(nodeText);
								if(!valid){
									$(this).removeClass('show');
									$(this).hide();
									//will go through all the parents and hides the parent if there are no
									// showable child nodes
									$(this).parents('li.parent').each(function(){
										var fileNodes = $(this).find('li.show.child');
										if( fileNodes.length == 0 ){
											$(this).hide();
											$(this).removeClass('show');
										}
									});
								}else{
									$(this).addClass('show');
									$(this).show();
									$(this).children('a').first().navigateToNode();
									$(this).parents(' li.parent').each(function(){
										$(this).children("a").first().navigateToNode();
										$(this).show();
										$(this).addClass('show');
									});
								}
							
							});
						}

						

						
						
					});
					
					/*Updates the scroll on each click*/
					$.fn.extend({
						updateSlimScroll : function() {
							$("#side").slimscroll({height : 'auto'});
							$("#side").slimscrollH({height : 'auto'});
							$('#side').css('height','98%');

						}

					});

						
					
					//initialise vertical slim scroll
					$('#side').slimscroll({
						height : 'auto',
						wheelStep : 2,
						disableFadeOut : true,
						distance : 5
					});
					//initialise horizontal slim scroll
					$('#side').slimscrollH({
						height : 'auto',
						size : 8,
						disableFadeOut : true,
						distance : 5
						
					});
					//set current selection to first node
					var curSelection = $('.tree li.parent').first();
					$(this).revealFirstNode();
					$('#side').css('height','98%');

				});

