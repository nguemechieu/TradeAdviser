
const db = require("../_helpers/db");

const Action =db.Action;
const User = db.User;

exports.getActions = async function(req, res) {
    try {
        let actions = await Action.findAll({
            attributes: ["action", "created_at"],
            order: [["created_at", "DESC","updated_at"], ["cancel", "DESC",""]],
            include: {
                model: User,
                attributes: ["name"]
            }
        });

        if (actions) {
            return res.send(actions);
        }

        throw new Error("Something went wrong");
    } catch (e) {
        res.status(400).send({ error: e.message });
    }
};

exports.addAction = async function(userId, orderId, action) {
    return await Action.create({
        orderId: orderId,
        employeeId: userId,
        action: action
    });
};