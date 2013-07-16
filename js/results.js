/* The root URL for REST api */
var rootURL = "http://git_data.dom/api";

$(document).ready(function () {
    /* Display the election results when page is loaded */
    if (window.location.pathname.match(/index\.php/))
    {
        //allCommits();
        var repo = $('#repo').val();
        var group = $('#group').val();
        var pack = $('#package').val();
        getChurn(repo, group, pack);
    }
});

$('#repo').click(function(event) {
    var repo = $('#repo').val(); 

    var list = "<option selected=\"selected\">All Packages</option>";

    $.ajax({
        type: 'GET',
        url: rootURL + '/packages/' + repo,
        dataType: "json", // data type of response
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
        //var quantity = $('#quantity').val();

        /* Pass these values to the function that gets the data using
           REST and plots it */
        //console.log(pack)
        pack = pack.replace(/\//g, '!');
        //console.log(pack)
        getChurn(repo, group, pack);

        event.preventDefault();
    });

function getChurn(repo, group, pack) { //encodeURIComponent()
    $.ajax({
        type: 'GET',
        url: rootURL + '/commitsChurn/' + repo + "/" + group + "/" + encodeURIComponent(pack),
        dataType: "json", // data type of response
        success: function(data) {
            plotChurn(data, repo, group, pack);
        }
    });
}

function plotChurn(data, repo, group, pack) {
    console.log(pack);
    //console.log(encodeURIComponent(pack));
    console.log(data);

    keys = Object.keys(data);
    dataLength = data[keys[0]].length;

    // Start from index one since the first is the date.
    var statsArray = {};
    statsArray[keys[1]] = new Array(dataLength);
    statsArray[keys[2]] = new Array(dataLength);
    statsArray[keys[3]] = new Array(dataLength);
    statsArray[keys[4]] = new Array(dataLength);
    statsArray[keys[5]] = new Array(dataLength);
    statsArray[keys[6]] = new Array(dataLength);

    // Linearize the elements and add the date to them.
    for(var j = 0; j < dataLength; j++) {
        statsArray[keys[1]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[1]][j])];
        statsArray[keys[2]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), (-1) * parseInt(data[keys[2]][j])];
        statsArray[keys[3]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[3]][j])];
        statsArray[keys[4]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), (-1) * parseInt(data[keys[4]][j])];
        statsArray[keys[5]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[5]][j])];
        statsArray[keys[6]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[6]][j])];
    }

    console.log(statsArray)
    areaPlotChurn("container", statsArray[keys[1]], statsArray[keys[2]], statsArray[keys[3]], statsArray[keys[4]], statsArray[keys[5]], statsArray[keys[6]], repo, group);
    //var comments = new Array(data["comments"].length);
    //var code = new Array(data["code"].length);
}

function plotCommits(data) {

    //var results = value == null ? [] : (value instanceof Array ? value : [value]);

    //console.log(data)
    var comments = new Array(data["comments"].length);
    var code = new Array(data["code"].length);
    for (var i = 0; i < data["date"].length; i++) {

        //comments[i] = [moment(data["date"][i], "YYYY-MM-DD HH:mm:ss").toDate(), data["comments"][i]];
        //code[i] = [moment(data["date"][i], "YYYY-MM-DD HH:mm:ss").toDate(), data["code"][i]];

        comments[i] = [moment(data["date"][i], "YYYY-MM-DD").valueOf(), parseInt(data["comments"][i])];
        code[i] = [moment(data["date"][i], "YYYY-MM-DD").valueOf(), parseInt(data["code"][i])];
        //console.log(comments[i])

        //Do something
    }

    console.log(comments);
    console.log(code);

    areaPlot("container", comments, code)
    //plotPieChart(position, results);
    
}

function areaPlot(id, comments, code) {

    var chart = $('#container').highcharts({
        chart: {
            type: 'area'
            //xAxis: data["date"]
        },
        title: {
            text: 'Total Comments and Code Per day'
        },
        subtitle: {
            //TODO set to db query
            text: "nostra13" + "/" + "Android-Universal-Image-Loader"
        },
        xAxis: {
            type: 'datetime',
            labels: {
            formatter: function () {
                return Highcharts.dateFormat('%b %Y', this.value);
            },
            dateTimeLabelFormats: {
                month: '%b \'%y',
                year: '%Y'
            }
        }
        },
        yAxis: {
            title: {
                text: 'Number of Lines'
            },
            labels: {
                formatter: function() {
                    return this.value / 1000 +'k';
                }
            }
        },
        tooltip: {
            pointFormat: 'Number of Lines of {series.name}: <b>{point.y:,.0f}</b><br/>',
            shared: true
        },
        plotOptions: {
            area: {
                
                marker: {
                    enabled: false,
                    symbol: 'circle',
                    radius: 2,
                    states: {
                        hover: {
                            enabled: true
                        }
                    }
                }
            }
        },
        series: [{
            name: 'Code',
            data: code,
            color: 'rgba(0, 0, 255, 0.7)'
            //color: 'rgba(255, 255, 255, 0.7)'
        }, {
            name: 'Comments',
            data: comments,
            color: 'rgba(0, 255, 0, 0.7)'
        }]
    });
}

function areaPlotChurn(id, commentsAdded, commentsDeleted, codeAdded, codeDeleted, totalComment, totalCode, repo, group) {

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
                //step: 2,
                staggerLines: 2,
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
            enabled: true
        },

        legend:{
            enabled: true
        },


        rangeSelector:{
            enabled:true,
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

        yAxis: [{
            title: {
                text: 'Number of Lines'
            },
            labels: {
                formatter: function() {
                    return this.value / 1000 +'k';
                }
            }
        },{ // Secondary yAxis
            title: {
                text: 'Total Number of Lines'
            },
            labels: {
                formatter: function() {
                    return this.value / 1000 +'k';
                }
            },
            opposite: true
        }],
        tooltip: {
            pointFormat: 'Number of Lines of {series.name}: <b>{point.y:,.0f}</b><br/>',
            shared: true
        },
        plotOptions: {
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
            data: commentsAdded,
            color: 'rgba(0, 255, 0, 0.8)',
            yAxis: 0
            //color: 'rgba(255, 255, 255, 0.7)'
        }, {
            type: 'spline',
            name: 'Comments Deleted',
            data: commentsDeleted,
            color: 'rgba(255, 0, 0, 0.8)',
            yAxis: 0
        }, {
            type: 'spline',
            name: 'Code Added',
            data: codeAdded,
            color: 'rgba(0, 0, 255, 0.8)',
            yAxis: 0
        }, {
            type: 'spline',
            name: 'Code Deleted',
            data: codeDeleted,
            color: 'rgba(125, 0, 255, 0.8)',
            yAxis: 0
        }, {
            type: 'column',
            name: 'Total Comments',
            data: totalComment,
            color: 'rgba(0, 100, 0, 0.5)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
        }, {
            type: 'column',
            name: 'Total Code',
            data: totalCode,
            color: 'rgba(29, 41, 81, 0.5)',
            yAxis: 1,
            dataGrouping: {
                approximation: "average"
            }
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