Jm doc "Demo of the Niner theme with 3x3 page navigation."
# See http://jeelabs.org/2011/09/10/a-site-for-the-home/ for the basic idea.

Niner layout {
  config: {
    title "Niner demo"
  }
  pages: {
    Status: {
      Overview: {}
      History: {}
      Full: { title "Full Status" }
    }
    Control: {
      Events: {}
      Rules: {}
      Manual: { title "Manual Control" }
    }
    Admin: {
      Configuration: { title "Configuration" }
      Devices: { title "Devices" }
      Software: { title "Software" }
    }
  }
}

proc NINER.INFOS {} {
  return {
    html-sif {
      % set map {1 ONE 2 TWO 3 THREE 4 FOUR 5 FIVE 6 SIX 7 SEVEN 8 EIGHT 9 NINE}
      .row
         .grid_16.columns#header
            h1: [Niner pageTitle $pageId]
            .nest
              .grid_8
                p: This is page [dict get $map $pageId].
                h2: haha
                p: Lorem ipsum dolor sit amet, consectetur \
                    adipisicing elit, sed do eiusmod tempor \
                     incididunt ut labore et dolore magna aliqua.
                h3: haha
                  p: Lorem ipsum dolor sit amet, consectetur.
                h4: haha
                  p: Lorem ipsum dolor sit amet, consectetur.
                h5: haha
                  p: Lorem ipsum dolor sit amet, consectetur.
                  p: Lorem ipsum dolor sit amet, consectetur.
              .grid_8
                p: Lorem ipsum dolor sit amet.
                pre: one\ntwo\nthree\n1234567890123456789012345678901234567890
                p: Lorem ipsum dolor sit amet.
    }
  }
}
