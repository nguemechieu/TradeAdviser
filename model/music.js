const {DataTypes, Sequelize} = require("sequelize");
 let musicModel =
    function MusicModel(sequelize) {

        const attributes = {


                name: {type: DataTypes.STRING, allowNull: false},
               dateTime: {type: DataTypes.DATE, allowNull: false, defaultValue: sequelize.DATE},// default is false for null values
                author: {type: DataTypes.STRING, allowNull: false, defaultValue: Sequelize.String},
                isActive: {type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true},// defaultValue is false for null values

            }

        const options = {
            defaultScope: {
                // exclude password hash by default
                //attributes: { exclude: ['passwordHash'] }
            },
            scopes: {
                // include hash with this scope
                withHash: { attributes: {}, }
            }
        };



            return sequelize.define('music', attributes, options);

        }

            module.exports = musicModel;