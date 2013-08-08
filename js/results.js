/* The root URL for REST api */
var rootURL = "http://git_data.dom/api";

$(document).ready(function () {
    /* Display the election results when page is loaded */
    if (window.location.pathname.match(/index\.php/))
    {
        $('#commit_info_panel').hide();
        //allCommits();
        var repo = $('#repo').val();
        var group = $('#group').val();
        var pack = $('#package').val();
        var thre = $('#threshold').val();

        exten = "";
        if (thre == "0.5")
        {
            exten = "05";
        }
        else if (thre == "0.5 M")
        {
            exten = "05_M";
        }
        else if (thre == "1.0")
        {
            exten = "10";
        }
        else if (thre == "1.0 M")
        {
            exten = "10_M";
        }
        else if (thre == "S = 20, H = 0.8, L = 0.5 M")
        {
            exten = "20_08_05_M";
        }
        getChurn(repo, group, pack, exten);
    }
});

$('#repo').click(function(event) {
    var repo = $('#repo').val(); 

    var list = "<option selected=\"selected\">All Packages</option>";

    $.ajax({
        type: 'GET',
        url: rootURL + '/packages/' + repo,
        dataType: "json", 
        success: function(data) {
            length = data.length;

            for (var i = 0; i < length; i++)
            {
                list += "<option>"+data[i]+"</option>";
            }

            //console.log(list);
            $('#package').html(list);
        }
    });
});

$('#update').click(function(event) {
        /* Get the unique session id and POST data */
        var repo = $('#repo').val();
        var group = $('#group').val();
        var pack = $('#package').val();
        var thre = $('#threshold').val();

        exten = "";
        if (thre == "0.5")
        {
            exten = "05";
        }
        else if (thre == "0.5 M")
        {
            exten = "05_M";
        }
        else if (thre == "1.0")
        {
            exten = "10";
        }
        else if (thre == "1.0 M")
        {
            exten = "10_M";
        }
        else if (thre == "S = 20, H = 0.8, L = 0.5 M")
        {
            exten = "20_08_05_M";
        }
        
        /* Pass these values to the function that gets the data using
           REST and plots it */
        //console.log(pack)

        $('#commit_info_panel').hide();

        pack = pack.replace(/\//g, '!');
        //console.log(pack)
        getChurn(repo, group, pack, exten);

        event.preventDefault();
    });

function getChurn(repo, group, pack, thre) {
    console.log(rootURL + '/commitsChurn/' + thre + "/" + repo + "/" + group + "/" + encodeURIComponent(pack));
    $.ajax({
        type: 'GET',
        url: rootURL + '/commitsChurn/' + thre + "/" + repo + "/" + group + "/" + encodeURIComponent(pack),
        dataType: "json", // data type of response
        success: function(data) {
            //console.log(rootURL + '/commitsChurn/' + thre + "/" + repo + "/" + group + "/" + encodeURIComponent(pack));
            plotChurn(data, repo, group, pack);
        }
    });
}

function plotChurn(data, repo, group, pack) {
    console.log(pack);
    //console.log(encodeURIComponent(pack));
    //console.log(data);

    churnData = data[0]
    tagData = data[1]
    keys = Object.keys(churnData);
    //console.log(keys)
    dataLength = churnData[keys[0]].length;

    // Start from index one since the first is the date.
    var statsArray = {};
    first = true;
    for (var i = 0; i < keys.length; i++) {
        if (keys[i] != "date" && keys[i] != "committer_name" && keys[i] != "author_name" && keys[i] != "body")
        {
            statsArray[keys[i]] = new Array(dataLength);
        }
        else if (first)
        {
            statsArray["ExtraData"] = new Array(dataLength);
            first = false;
        }
    }

    var commit_level = $.inArray("committer_name", keys) != -1

    // Linearize the elements and add the date to them.
    for(var j = 0; j < dataLength; j++) {

        for (var k = 0; k < keys.length; k++) {
            if (keys[k] == "commentsDeleted" || keys[k] == "codeDeleted")
            {
                /*if (commit_level && keys[k] == "commentsAdded")
                {
                    statsArray[keys[k]][j] = {x: moment(churnData[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), y: (-1) * parseInt(churnData[keys[k]][j]), myData: [churnData["committer_name"][j], churnData["author_name"][j], churnData["body"][j]]};
                }  
                else
                {*/
                    statsArray[keys[k]][j] = {x: moment(churnData["date"][j], "YYYY-MM-DD HH:mm:ss").valueOf(), y: (-1) * parseInt(churnData[keys[k]][j])};
                //}
            }
            else if (keys[k] == "date" || keys[k] == "committer_name" || keys[k] == "author_name" || keys[k] == "body")
            {
                
            }
            else
            {
                /*if (commit_level && keys[k] == "commentsAdded")
                {
                    statsArray[keys[k]][j] = {x: moment(churnData[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), y: parseInt(churnData[keys[k]][j]), myData: [churnData["committer_name"][j], churnData["author_name"][j], churnData["body"][j]]};
                }
                else
                {*/
                    statsArray[keys[k]][j] = {x: moment(churnData["date"][j], "YYYY-MM-DD HH:mm:ss").valueOf(), y: parseInt(churnData[keys[k]][j])};
                //}
            }  

        }
        if (commit_level)
        {
            //break;
            //user[moment(churnData[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf()] = churnData[keys[k]][j];
            statsArray["ExtraData"][j] = {x: moment(churnData["date"][j], "YYYY-MM-DD HH:mm:ss").valueOf(), y: j, myData: {com: churnData["committer_name"][j], aut: churnData["author_name"][j], body: churnData["body"][j]}};
        }
    }

    console.log(statsArray);

    var tagArray = [];
    tagKeys = Object.keys(tagData);
    dataLength = tagData[tagKeys[0]].length;

    //console.log(tagData);
    /*for (var i = 0; i < tagKeys.length; i++) {
        tagArray[i] = {};
    }*/
    
    for (var i = 0; i < dataLength; i++) {

        if (tagData["desc"][i] == "")
        {
            tagData["desc"][i] = tagData["name"][i];
        }

        tagArray.push({
            x: moment(tagData[tagKeys[0]][i], "YYYY-MM-DD HH:mm:ss").valueOf(),
            title: tagData["name"][i],
            text: tagData["desc"][i]
        }); 
    }
    
    //console.log(tagArray);
    
    areaPlotChurn("container", statsArray, repo, group, tagArray);
}

var PageHeight
$(document).ready(function(){
    if ($(window).height()*0.8 > 600)
    {
        $('#container').height($(window).height()*0.8);
    }
    PageHeight = $('#container').height();
    console.log(PageHeight);
});

function areaPlotChurn(id, stats, repo, group, tagInfo) {

    //
    var chart = $('#container').highcharts('StockChart', {
        chart: {
            //,
            //zoomType: 'x'
            //xAxis: data["date"]
        },
        title: {
            text: 'Comments and Code Churn Per ' + group
        },
        subtitle: {
            //TODO set to db query
            text: '<a href="http://github.com/' + repo + '" target="_blank">'+repo+'</a>',
            useHTML: true
        },
        xAxis: {
            type: 'datetime',
            //maxZoom: 14 * 24 * 3600000,

            labels: {
                enabled: true,
                //step: 2,
                //staggerLines: 2,
                formatter: function () {
                    return Highcharts.dateFormat('%b %d %Y', this.value);
                },
                dateTimeLabelFormats: {
                    month: '%b \'%y',
                    year: '%Y'
                }
            }
        },

        navigator: {
            enabled: true, 
            height: 20
        },

        legend:{
            enabled: true
        },

        rangeSelector:{
            enabled: true,
            buttons: [{
                type: 'month',
                count: 1,
                text: '1m'
            }, {
                type: 'month',
                count: 3,
                text: '3m'
            }, {
                type: 'month',
                count: 6,
                text: '6m'
            }, {
                type: 'ytd',
                text: 'YTD'
            }, {
                type: 'year',
                count: 1,
                text: '1y'
            }, {
                type: 'all',
                text: 'All'
            }]
        },

        //TODO get the height of the container and store is as a varaible to use here
        yAxis: [{
            title: {
                text: 'Number of Lines'
            },
            labels: {
                formatter: function() {
                    return this.value / 1000 +'k';
                }
            },
            height: PageHeight*0.45,
            lineWidth: 2
        },{ // Secondary yAxis
            title: {
                text: 'Total Number of Lines'
            },
            labels: {
                formatter: function() {
                    return this.value / 1000 +'k';
                }
            },
            top: PageHeight*0.57,
            height: PageHeight*0.20,
            offset: 0,
            lineWidth: 2
        }],
        tooltip: {
            formatter: function(i) {

                var s = '<b>'+ Highcharts.dateFormat('%A, %b %e, %Y', this.x) +'</b>';
                
                if (this.point == undefined)
                {
                    var index = this.points.length-1;
                    var y_point = Math.round(this.points[index].y);
                    console.log(y_point);
                    
                    if (this.points[index].series.name == "ExtraData" && this.points[index].series.userOptions.data[y_point] != undefined)
                    {
                        s += '<br>Committed By: <b> ' + this.points[index].series.userOptions.data[y_point].myData["com"] + '</b></br>';
                        s += '<br>Authored By: <b> ' + this.points[index].series.userOptions.data[y_point].myData["aut"] + '</b></br>';

                        document.getElementById('commit_message').innerHTML = this.points[index].series.userOptions.data[y_point].myData["body"]
                        $('#commit_info_panel').show();
                    }

                    $.each(this.points, function(i, point) {
                        
                        if (point.series.name == 'Releases')
                        {
                            s += '<br>Release </br>';
                        }
                        else {
                            if(point.series.name !== 'Total Comments Column' && point.series.name !== 'Total Comments Modified Column' && point.series.name !== 'Total Code Column' && point.series.name !== 'Total Code Modified Column')
                            {
                                s += '<br>Number of Lines of ' + point.series.name + ': <b> ' + Math.round(point.y) + '</b></br>';
                            }
                        }
                    });
                }
                else
                {
                    s += '<br>' + this.series.name + ': <b> ' + this.point.text + '</b></br>';
                }
                return s;
            },
            shared: true 
        },
        plotOptions: {
            series: {
                turboThreshold: 0,
            },
            spline: {
                
                marker: {
                    enabled: false//,
                    //symbol: 'circle',
                    //radius: 2,
                    //states: {
                    //    hover: {
                    //        enabled: true
                    //    }
                    //}
                }
            }
        },
        series: [{
            type: 'spline',
            name: 'Comments Added',
            data: stats["commentsAdded"],
            color: 'rgba(205,92,92, 0.9)',
            yAxis: 0,
            stack: 'comment',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
            //color: 'rgba(255, 255, 255, 0.7)'
        }, {
            type: 'spline',
            name: 'Comments Deleted',
            data: stats["commentsDeleted"],
            color: 'rgba(220,20,60, 0.9)',
            yAxis: 0,
            stack: 'comment',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
        }, {
            type: 'spline',
            name: 'Comments Modified',
            data: stats["commentsModified"],
            color: 'rgba(139,0,0, 0.9)',
            yAxis: 0,
            stack: 'comment',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
        }, {
            id: 'codeadded',
            type: 'spline',
            name: 'Code Added',
            data: stats["codeAdded"],
            color: 'rgba(135,206,235, 0.9)',
            yAxis: 0,
            stack: 'code',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
        }, {
            type: 'spline',
            name: 'Code Deleted',
            data: stats["codeDeleted"],
            color: 'rgba(70,130,180, 0.9)',
            yAxis: 0,
            stack: 'code',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
        }, {
            type: 'spline',
            name: 'Code Modified',
            data: stats["codeModified"],
            color: 'rgba(0,0,128, 0.9)',
            yAxis: 0,
            stack: 'code',
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
        }, {
            id: 'Total Comments',
            type: 'spline',
            name: 'Total Comments',
            data: stats["totalComments"],
            color: 'rgba(205,92,92, 0.9)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        }, {
            linkedTo: 'Total Comments',
            type: 'column',
            name: 'Total Comments Column',
            data: stats["totalComments"],
            color: 'rgba(205,92,92, 0.3)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        }, {
            id: 'Total Comments Modified',
            type: 'spline',
            name: 'Total Comments Modified',
            data: stats["totalCommentsModified"],
            color: 'rgba(139,0,0, 0.9)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        }, {
            type: 'column',
            name: 'Total Comments Modified Column',
            data: stats["totalCommentsModified"],
            color: 'rgba(139,0,0, 0.3)',
            yAxis: 1,
            linkedTo: 'Total Comments Modified',
            dataGrouping: {
                approximation: "average"
            }
        }, {
            id: 'Total Code',
            type: 'spline',
            name: 'Total Code',
            data: stats["totalCode"],
            color: 'rgba(70,130,180, 0.9)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        }, {
            type: 'column',
            name: 'Total Code Column',
            data: stats["totalCode"],
            color: 'rgba(70,130,180, 0.3)',
            yAxis: 1,
            linkedTo: 'Total Code',
            dataGrouping: {
                approximation: "average"
            }
        }, {
            id: 'Total Code Modified',
            type: 'spline',
            name: 'Total Code Modified',
            data: stats["totalCodeModified"],
            color: 'rgba(0,0,128, 0.9)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        },  {
            type: 'column',
            name: 'Total Code Modified Column',
            data: stats["totalCodeModified"],
            color: 'rgba(0,0,128, 0.3)',
            yAxis: 1,
            linkedTo: 'Total Code Modified',
            dataGrouping: {
                approximation: "average"
            }
        }, {
            type: 'flags',
            data: tagInfo,
            shape: 'circlepin',
            title: "Releases",
            name: "Releases"
        }, {
            type: 'spline',
            name: 'ExtraData',
            data: stats["ExtraData"],
            color: 'rgba(255,255,255, 0.0)',
            yAxis: 0,
            //stack: 'comment',
            //visible: false,
            showInLegend: false,
            dataGrouping: {
                //enabled: false,
                approximation: "average"
            }
            //color: 'rgba(255, 255, 255, 0.7)'
        }]
    }, function(chart){

            // apply the date pickers
            setTimeout(function () {
                $('input.highcharts-range-selector', $(chart.container).parent())
                    .datepicker();
            }, 0);
    });
}

$(function() {
    // Set the datepicker's date format
    $.datepicker.setDefaults({
        dateFormat: 'yy-mm-dd',
        onSelect: function(dateText) {
            this.onchange();
            this.onblur();
        }
    });
});