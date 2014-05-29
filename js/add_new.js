$('#submit').click(function(event) {

    event.preventDefault();
    var user = $('#username').val(); 
    var repo = $('#repository').val();

    //TODO fix empty submit error

    //Ensure valid user
    //Make rest call

    if(user == "" && repo == "")
    {
        if(user == "")
        {
            // Tell user to enter a valid username
        }

        if(repo == "")
        {
            //Tell user to enter a valid repo name
        }
    }
    else
    {
        $.ajax({
            type: 'GET',
            url: rootURL + '/newrepo/' + encodeURIComponent(user) + "/" + encodeURIComponent(repo),
            dataType: "json", 
            success: function(data) {
                
                //Tell the user about success
            },
            error: function(data) {
                //Tell the user how their input was wrong
            }
        }); 
    }

});