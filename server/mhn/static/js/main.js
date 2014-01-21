$(document).ready(function() {
    if ($('#sensor-fields').length >= 1) {
        $('#create-btn').click(function() {
            var sensorObj = {
                name: $('#name').val(),
                hostname: $('#hostname').val()
            }
            $('#alert-row').hide();
            $.ajax({
                type: 'POST',
                url: '/api/sensor/',
                data: JSON.stringify(sensorObj),
                success: function(resp) {
                    $('#sensor-info').show();
                    $('#sensor-id').html('UUID: ' + resp.uuid);
                },
                contentType: 'application/json',
                error: function(resp) {
                    $('#alert-row').show();
                    $('#alert-text').html(resp.responseJSON.error);
                }
            });
        });
    }
});
