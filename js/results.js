/* The root URL for REST api */
var rootURL = "http://git_data.dom/api";

$(document).ready(function () {
    /* Display the election results when page is loaded */
    if (window.location.pathname.match(/index\.php/))
    {
        //allCommits();
        getChurn();
    }
});

function allCommits() {
    $.ajax({
        type: 'GET',
        url: rootURL + '/commits',
        dataType: "json", // data type of response
        success: function(data) {
            plotCommits(data);
        }
    });
}

function getChurn() {
    $.ajax({
        type: 'GET',
        url: rootURL + '/commitsChurn',
        dataType: "json", // data type of response
        success: function(data) {
            plotChurn(data);
        }
    });
}

function plotChurn(data) {
    console.log(data);

    keys = Object.keys(data);
    dataLength = data[keys[0]].length;

    // Start from index one since the first is the date.
    var statsArray = {};
    statsArray[keys[1]] = new Array(dataLength);
    statsArray[keys[2]] = new Array(dataLength);
    statsArray[keys[3]] = new Array(dataLength);
    statsArray[keys[4]] = new Array(dataLength);

    // Linearize the elements and add the date to them.
    for(var j = 0; j < dataLength; j++) {
        statsArray[keys[1]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[1]][j])];
        statsArray[keys[2]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), (-1) * parseInt(data[keys[2]][j])];
        statsArray[keys[3]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), parseInt(data[keys[3]][j])];
        statsArray[keys[4]][j] = [moment(data[keys[0]][j], "YYYY-MM-DD HH:mm:ss").valueOf(), (-1) * parseInt(data[keys[4]][j])];
    }

    console.log(statsArray)
    areaPlotChurn("container", statsArray[keys[1]], statsArray[keys[2]], statsArray[keys[3]], statsArray[keys[4]]);
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

function areaPlotChurn(id, commentsAdded, commentsDeleted, codeAdded, codeDeleted) {

    var chart = $('#container').highcharts({
        chart: {
            type: 'spline'
            //xAxis: data["date"]
        },
        title: {
            text: 'Comments and Code Churn Per Month'
        },
        subtitle: {
            //TODO set to db query
            text: "ACRA" + "/" + "acra"
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
            name: 'Comments Added',
            data: commentsAdded,
            color: 'rgba(255, 0, 0, 0.7)'
            //color: 'rgba(255, 255, 255, 0.7)'
        }, {
            name: 'Comments Deleted',
            data: commentsDeleted,
            color: 'rgba(0, 255, 0, 0.7)'
        }, {
            name: 'Code Added',
            data: codeAdded,
            color: 'rgba(0, 0, 255, 0.7)'
        }, {
            name: 'Code Deleted',
            data: codeDeleted,
            color: 'rgba(255, 0, 255, 0.7)'
        }]
    });
}