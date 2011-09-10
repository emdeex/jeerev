Jm doc "Demo of the Niner theme with 3x3 page navigation."

Niner setup {
  config: {
    title "Niner demo"
    handler "pageHandler $id"
  }
  pages: {
    Status: {
      Overview: {}
      History: {}
      Full: { title "Full Status" }
    }
    Control: {
      Triggers: {}
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

proc pageHandler {pageId} {
  set pageNames {1 ONE 2 TWO 3 THREE 4 FOUR 5 FIVE 6 SIX 7 SEVEN 8 EIGHT 9 NINE}
  Webserver expand [Sif html {
    .row
       .span16.columns#header
          h1: [Niner pageTitle $pageId]
          .nest
            .span8
              p: This is page [string map $pageNames $pageId].
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
            .span8
              p: Lorem ipsum dolor sit amet.
              pre: one\ntwo\nthree\n1234567890123456789012345678901234567890
              p: Lorem ipsum dolor sit amet.
  }]
}
