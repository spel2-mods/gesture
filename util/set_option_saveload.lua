local option_utils = require "util.option"

return function()
    set_callback(function(save_ctx)
        local save_data_str = json.encode({
            ["version"] = meta.version,
            ["options"] = options
        })
        save_ctx:save(save_data_str)
    end, ON.SAVE)

    set_callback(function(load_ctx)
        local save_data_str = load_ctx:load()
        if save_data_str ~= "" then
            local save_data = json.decode(save_data_str)
            if save_data.options then
                options = save_data.options
                option_utils.load_default_options()
            end
        end
    end, ON.LOAD)

    option_utils.load_default_options()
end
